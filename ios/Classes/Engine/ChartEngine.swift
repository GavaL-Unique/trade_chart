import CoreGraphics
import Flutter
import Foundation
import QuartzCore

final class ChartEngine: NSObject {
  init(chartId: Int64, textureRegistry: FlutterTextureRegistry, flutterApiHolder: ChartFlutterApiHolder) {
    self.chartId = chartId
    self.flutterApiHolder = flutterApiHolder
    textureRenderer = TextureRenderer(textureRegistry: textureRegistry)
    candleStore = CandleStore()
    markerStore = MarkerStore()
    viewport = ViewportCalculator()
    renderers = [
      BackgroundRenderer(),
      GridRenderer(),
      VolumeRenderer(),
      CandleRenderer(),
      LineRenderer(),
      MarkerRenderer(),
      AxisRenderer(),
      CrosshairRenderer(),
    ]
    super.init()
  }

  private let chartId: Int64
  private let flutterApiHolder: ChartFlutterApiHolder
  private let textureRenderer: TextureRenderer
  private let candleStore: CandleStore
  private let markerStore: MarkerStore
  private let viewport: ViewportCalculator
  private let renderers: [ChartLayerRenderer]

  private var theme: NativeChartTheme?
  private var config: ConfigMessage?
  private var chartType: String = "candle"
  private var width: Int = 1
  private var height: Int = 1
  private var scale: CGFloat = 1.0
  private var dirty: Bool = false
  private var frameScheduled: Bool = false
  private var lastFrameTime: CFTimeInterval = 0
  private var viewportChangedPending: Bool = false
  private var pendingCrosshairData: CrosshairDataMessage?
  private var crosshairState: CrosshairState?
  private var flingVelocityX: Double = 0
  private var flingActive: Bool = false
  private var isDisposed: Bool = false
  private var displayLink: CADisplayLink?

  var textureId: Int64 {
    textureRenderer.textureId
  }

  func initialize(params: ChartInitParams) {
    width = max(Int(params.width), 1)
    height = max(Int(params.height), 1)
    scale = max(CGFloat(params.devicePixelRatio), 1.0)
    theme = NativeChartTheme(message: params.theme)
    config = params.config
    chartType = params.config.initialChartType
    textureRenderer.resize(width: width, height: height, scale: scale)
    dirty = true
    renderCurrentFrame()
    flutterApiHolder.onChartReady(chartId: chartId)
    flutterApiHolder.onViewportChanged(chartId: chartId, viewport: viewportState())
  }

  func dispose() {
    isDisposed = true
    invalidateDisplayLink()
    textureRenderer.releaseTexture()
  }

  func onSizeChanged(width: Double, height: Double) {
    self.width = max(Int(width), 1)
    self.height = max(Int(height), 1)
    textureRenderer.resize(width: self.width, height: self.height, scale: scale)
    recomputeViewport()
    markDirty(viewportChanged: candleStore.count > 0)
  }

  func loadCandles(data: CandleDataListMessage) {
    candleStore.load(data: data)
    recomputeViewport()
    markDirty(viewportChanged: true)
  }

  func appendCandle(candle: CandleDataMessage) {
    let previousCount = candleStore.count
    if let lastTimestamp = candleStore.lastTimestampOrNil(), candle.timestamp <= lastTimestamp {
      return
    }
    let wasAtLatest = viewport.isAtLatest
    candleStore.append(candle: candle)
    recomputeViewportForAppend(wasAtLatest: wasAtLatest, isFirstCandle: previousCount == 0)
    let viewportChanged = previousCount == 0 || (wasAtLatest && (config?.autoScrollOnAppend ?? false))
    markDirty(viewportChanged: viewportChanged)
  }

  func updateLastCandle(candle: CandleDataMessage) {
    if let lastTimestamp = candleStore.lastTimestampOrNil(), candle.timestamp != lastTimestamp {
      return
    }
    let lastWasVisible = candleStore.count == 0 ||
      (viewport.hasVisibleRange() && viewport.visibleEndIndex == candleStore.count - 1)
    candleStore.updateLast(candle: candle)
    if lastWasVisible {
      recomputeViewport()
    }
    markDirty(viewportChanged: lastWasVisible)
  }

  func setMarkers(markers: MarkerListMessage) {
    if markers.markers.isEmpty && candleStore.count == 0 {
      markerStore.set(markers: [])
      return
    }
    markerStore.set(markers: markers.markers)
    markDirty()
  }

  func addMarker(marker: MarkerMessage) {
    markerStore.add(marker: marker)
    markDirty()
  }

  func clearMarkers() {
    if candleStore.count == 0 {
      markerStore.clear()
      return
    }
    markerStore.clear()
    markDirty()
  }

  func setChartType(chartType: String) {
    self.chartType = chartType
    recomputeViewport()
    markDirty(viewportChanged: candleStore.count > 0)
  }

  func setTimeframe(timeframe: String) {
    candleStore.clear()
    crosshairState = nil
    pendingCrosshairData = nil
    endFling()
    recomputeViewport()
    dirty = true
    renderCurrentFrame()
    dirty = false
    flutterApiHolder.onViewportChanged(chartId: chartId, viewport: viewportState())
  }

  func setTheme(theme: ThemeMessage) {
    self.theme = NativeChartTheme(message: theme)
    markDirty()
  }

  func setConfig(config: ConfigMessage) {
    self.config = config
    chartType = chartType.isEmpty ? config.initialChartType : chartType
    recomputeViewport()
    markDirty(viewportChanged: candleStore.count > 0)
  }

  func scrollToEnd() {
    guard let config else { return }
    endFling()
    if viewport.scrollToEnd(
      candleStore: candleStore,
      plotWidth: plotWidth(),
      config: config,
      chartType: chartType
    ) {
      markDirty(viewportChanged: true)
    }
  }

  func onPanUpdate(deltaX: Double) {
    guard let config else { return }
    endFling()
    if viewport.applyPanDelta(
      deltaX: deltaX,
      candleStore: candleStore,
      plotWidth: plotWidth(),
      config: config,
      chartType: chartType
    ) {
      markDirty(viewportChanged: true)
    }
  }

  func onPanEnd(velocityX: Double) {
    guard abs(velocityX) >= 50, candleStore.count > 0 else {
      endFling()
      return
    }
    flingVelocityX = velocityX
    flingActive = true
    lastFrameTime = 0
    scheduleFrame()
  }

  func onScaleUpdate(scaleFactor: Double, focalPointX: Double) {
    guard let config else { return }
    endFling()
    if viewport.applyScale(
      scaleFactor: scaleFactor,
      focalPointX: focalPointX,
      candleStore: candleStore,
      plotWidth: plotWidth(),
      config: config,
      chartType: chartType
    ) {
      markDirty(viewportChanged: true)
    }
  }

  func onScaleEnd() {
    viewport.endScaleGesture()
  }

  func onCrosshairStart(x: Double, y: Double) {
    guard config?.enableCrosshair != false else { return }
    let layout = createLayout()
    guard let resolved = viewport.resolveCrosshair(
      x: x,
      y: y,
      contentRect: layout.contentRect,
      mainChartRect: layout.mainChartRect,
      candleStore: candleStore
    ) else {
      return
    }
    crosshairState = CrosshairState(
      candleIndex: resolved.candleIndex,
      snappedX: resolved.snappedX,
      y: resolved.y
    )
    pendingCrosshairData = crosshairDataMessage(crosshairState!)
    markDirty()
  }

  func onCrosshairMove(x: Double, y: Double) {
    guard config?.enableCrosshair != false else { return }
    let layout = createLayout()
    guard let resolved = viewport.resolveCrosshair(
      x: x,
      y: y,
      contentRect: layout.contentRect,
      mainChartRect: layout.mainChartRect,
      candleStore: candleStore
    ) else {
      return
    }
    crosshairState = CrosshairState(
      candleIndex: resolved.candleIndex,
      snappedX: resolved.snappedX,
      y: resolved.y
    )
    pendingCrosshairData = crosshairDataMessage(crosshairState!)
    markDirty()
  }

  func onCrosshairEnd() {
    guard crosshairState != nil || pendingCrosshairData != nil else { return }
    crosshairState = nil
    pendingCrosshairData = nil
    markDirty()
  }

  private func recomputeViewport() {
    guard let config else { return }
    let layout = createLayout()
    viewport.refresh(
      candleStore: candleStore,
      plotWidth: layout.mainChartRect.width,
      config: config,
      chartType: chartType
    )
  }

  private func recomputeViewportForAppend(wasAtLatest: Bool, isFirstCandle: Bool) {
    guard let config else { return }
    if isFirstCandle {
      recomputeViewport()
      return
    }
    if wasAtLatest && config.autoScrollOnAppend {
      _ = viewport.scrollToEnd(
        candleStore: candleStore,
        plotWidth: plotWidth(),
        config: config,
        chartType: chartType
      )
      return
    }
    recomputeViewport()
  }

  private func renderCurrentFrame() {
    guard let theme, let config, !isDisposed else { return }
    let layout = createLayout()
    if candleStore.count > 0 {
      viewport.refresh(
        candleStore: candleStore,
        plotWidth: layout.mainChartRect.width,
        config: config,
        chartType: chartType
      )
    }

    let renderChartType = viewport.effectiveRenderChartType(userChartType: chartType)
    textureRenderer.render { context in
      let frame = ChartFrame(
        context: context,
        candleStore: candleStore,
        markerStore: markerStore,
        viewport: viewport,
        theme: theme,
        config: config,
        chartType: renderChartType,
        width: width,
        height: height,
        contentRect: layout.contentRect,
        mainChartRect: layout.mainChartRect,
        volumeRect: layout.volumeRect,
        priceAxisRect: layout.priceAxisRect,
        timeAxisRect: layout.timeAxisRect,
        crosshair: crosshairState
      )
      renderers.forEach { $0.render(frame: frame) }
    }
  }

  private func viewportState() -> ViewportStateMessage {
    guard candleStore.count > 0, viewport.hasVisibleRange() else {
      return ViewportStateMessage(
        startTimestamp: 0,
        endTimestamp: 0,
        priceHigh: 0,
        priceLow: 0,
        visibleCandleCount: 0,
        candleWidth: 0,
        isAtLatest: true
      )
    }
    return ViewportStateMessage(
      startTimestamp: candleStore.timestamp(at: viewport.visibleStartIndex),
      endTimestamp: candleStore.timestamp(at: viewport.visibleEndIndex),
      priceHigh: viewport.priceHigh,
      priceLow: viewport.priceLow,
      visibleCandleCount: Int64(viewport.visibleCandleCount),
      candleWidth: viewport.candleWidth,
      isAtLatest: viewport.isAtLatest
    )
  }

  private func markDirty(viewportChanged: Bool = false) {
    dirty = true
    if viewportChanged {
      viewportChangedPending = true
    }
    scheduleFrame()
  }

  private func scheduleFrame() {
    guard !frameScheduled, !isDisposed else { return }
    if displayLink == nil {
      let link = CADisplayLink(target: self, selector: #selector(handleDisplayLink(_:)))
      if #available(iOS 15.0, *) {
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 60, preferred: 60)
      }
      link.add(to: .main, forMode: .common)
      displayLink = link
    }
    frameScheduled = true
    displayLink?.isPaused = false
  }

  @objc
  private func handleDisplayLink(_ link: CADisplayLink) {
    frameScheduled = false
    if isDisposed {
      invalidateDisplayLink()
      return
    }

    if flingActive {
      updateFling(link.targetTimestamp)
    } else {
      lastFrameTime = 0
    }

    if candleStore.isAnimating {
      let dt = link.duration > 0 ? link.duration : 1.0 / 60.0
      candleStore.advanceAnimation(dt: dt)
      dirty = true
    }

    if dirty {
      renderCurrentFrame()
      dirty = false
      if viewportChangedPending {
        flutterApiHolder.onViewportChanged(chartId: chartId, viewport: viewportState())
        viewportChangedPending = false
      }
      if let pendingCrosshairData {
        flutterApiHolder.onCrosshairData(chartId: chartId, data: pendingCrosshairData)
        self.pendingCrosshairData = nil
      }
    }

    if flingActive || candleStore.isAnimating || dirty {
      frameScheduled = true
      return
    }

    displayLink?.isPaused = true
  }

  private func updateFling(_ frameTime: CFTimeInterval) {
    guard let config else { return }
    if lastFrameTime == 0 {
      lastFrameTime = frameTime
      return
    }
    let dt = frameTime - lastFrameTime
    lastFrameTime = frameTime
    guard dt > 0 else { return }

    let deltaX = flingVelocityX * dt
    let moved = viewport.applyPanDelta(
      deltaX: deltaX,
      candleStore: candleStore,
      plotWidth: plotWidth(),
      config: config,
      chartType: chartType
    )
    if moved {
      dirty = true
      viewportChangedPending = true
    }
    flingVelocityX *= Foundation.exp(-6 * dt)
    if abs(flingVelocityX) < 10 || !moved {
      endFling()
    }
  }

  private func endFling() {
    flingActive = false
    flingVelocityX = 0
    lastFrameTime = 0
  }

  private func plotWidth() -> Double {
    createLayout().mainChartRect.width
  }

  private func crosshairDataMessage(_ crosshair: CrosshairState) -> CrosshairDataMessage {
    CrosshairDataMessage(
      timestamp: candleStore.timestamp(at: crosshair.candleIndex),
      open: candleStore.open(at: crosshair.candleIndex),
      high: candleStore.high(at: crosshair.candleIndex),
      low: candleStore.low(at: crosshair.candleIndex),
      close: candleStore.close(at: crosshair.candleIndex),
      volume: candleStore.volume(at: crosshair.candleIndex),
      x: Double(crosshair.snappedX),
      y: Double(crosshair.y)
    )
  }

  private func invalidateDisplayLink() {
    displayLink?.invalidate()
    displayLink = nil
    frameScheduled = false
  }

  private func createLayout() -> Layout {
    guard let config else {
      let rect = CGRect(x: 0, y: 0, width: width, height: height)
      return Layout(
        contentRect: rect,
        mainChartRect: rect,
        volumeRect: nil,
        priceAxisRect: nil,
        timeAxisRect: nil
      )
    }

    let axisWidth: CGFloat = config.showAxis ? 56 : 0
    let timeAxisHeight: CGFloat = config.showAxis ? 24 : 0
    let contentRight = CGFloat(width) - axisWidth
    let contentBottom = CGFloat(height) - timeAxisHeight
    let contentRect = CGRect(x: 0, y: 0, width: contentRight, height: contentBottom)

    let volumeGap: CGFloat = config.showVolume ? 8 : 0
    let volumeHeight: CGFloat = config.showVolume
      ? max(48, contentRect.height * config.volumeHeightRatio)
      : 0
    let mainBottom = contentRect.maxY - volumeHeight - volumeGap
    let mainChartRect = CGRect(
      x: contentRect.minX,
      y: contentRect.minY,
      width: contentRect.width,
      height: config.showVolume ? max(32, mainBottom - contentRect.minY) : contentRect.height
    )
    let volumeRect = config.showVolume
      ? CGRect(
        x: contentRect.minX,
        y: mainChartRect.maxY + volumeGap,
        width: contentRect.width,
        height: max(0, contentRect.maxY - (mainChartRect.maxY + volumeGap))
      )
      : nil
    let priceAxisRect = config.showAxis
      ? CGRect(x: contentRect.maxX, y: 0, width: CGFloat(width) - contentRect.maxX, height: mainChartRect.maxY)
      : nil
    let timeAxisRect = config.showAxis
      ? CGRect(x: 0, y: contentBottom, width: CGFloat(width), height: CGFloat(height) - contentBottom)
      : nil

    return Layout(
      contentRect: contentRect,
      mainChartRect: mainChartRect,
      volumeRect: volumeRect,
      priceAxisRect: priceAxisRect,
      timeAxisRect: timeAxisRect
    )
  }

  private struct Layout {
    let contentRect: CGRect
    let mainChartRect: CGRect
    let volumeRect: CGRect?
    let priceAxisRect: CGRect?
    let timeAxisRect: CGRect?
  }
}
