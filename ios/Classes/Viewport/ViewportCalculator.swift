import CoreGraphics
import Foundation

struct ResolvedCrosshair {
  let candleIndex: Int
  let snappedX: CGFloat
  let y: CGFloat
}

final class ViewportCalculator {
  private(set) var visibleStartIndex: Int = 0
  private(set) var visibleEndIndex: Int = -1
  private(set) var visibleCandleCount: Int = 0
  private(set) var candleWidth: Double = 0
  private(set) var slotWidth: Double = 0
  private(set) var priceHigh: Double = 0
  private(set) var priceLow: Double = 0
  private(set) var maxVisibleVolume: Double = 0
  private(set) var isAtLatest: Bool = true
  private var viewportStart: Double = 0
  private var visibleCountDouble: Double = 0

  /// Fractional scroll position in candle index space (for time labels that track pan smoothly).
  var scrollOffset: Double { viewportStart }
  private var scaleBaseStart: Double?
  private var scaleBaseVisibleCount: Double?

  /// Below this slot width (logical points), candle mode renders as a close line (Bybit-style LOD).
  private static let candleLodMaxSlotWidth: Double = 4.0

  func resetToLatest(
    candleStore: CandleStore,
    plotWidth: Double,
    config: ConfigMessage,
    chartType: String
  ) {
    guard candleStore.count > 0, plotWidth > 0 else {
      clear()
      return
    }

    visibleCountDouble = Double(calculateVisibleCount(
      candleCount: candleStore.count,
      plotWidth: plotWidth,
      config: config
    ))
    viewportStart = maxStart(candleCount: candleStore.count)
    updateDerived(
      candleStore: candleStore,
      plotWidth: plotWidth,
      config: config,
      chartType: chartType
    )
  }

  func refresh(
    candleStore: CandleStore,
    plotWidth: Double,
    config: ConfigMessage,
    chartType: String
  ) {
    guard candleStore.count > 0, plotWidth > 0 else {
      clear()
      return
    }

    if visibleCountDouble <= 0 {
      resetToLatest(
        candleStore: candleStore,
        plotWidth: plotWidth,
        config: config,
        chartType: chartType
      )
      return
    }

    visibleCountDouble = min(
      Double(candleStore.count),
      min(Double(config.maxVisibleCandles), max(Double(config.minVisibleCandles), visibleCountDouble))
    )
    viewportStart = min(max(0, viewportStart), maxStart(candleCount: candleStore.count))
    updateDerived(
      candleStore: candleStore,
      plotWidth: plotWidth,
      config: config,
      chartType: chartType
    )
  }

  func hasVisibleRange() -> Bool {
    visibleCandleCount > 0 && visibleEndIndex >= visibleStartIndex
  }

  /// Renders candle mode as a line when zoomed out (matches price-range logic in `updateDerived`).
  func effectiveRenderChartType(userChartType: String) -> String {
    Self.rangeChartTypeForPriceBounds(chartType: userChartType, slotWidth: slotWidth)
  }

  /// Candle index for a fraction of the visible span (0 = left edge, 1 = right), for time-axis labels.
  func candleIndexAtVisibleRatio(_ t: Double, candleCount: Int) -> Int {
    guard hasVisibleRange(), candleCount > 0, visibleCountDouble > 0 else {
      return 0
    }
    let u = min(1.0, max(0.0, t))
    let raw = viewportStart + u * visibleCountDouble - 0.5
    let idx = Int(round(raw))
    return min(max(0, idx), candleCount - 1)
  }

  func xCenter(for index: Int, plotLeft: CGFloat) -> CGFloat {
    plotLeft + CGFloat((Double(index) - viewportStart) + 0.5) * CGFloat(slotWidth)
  }

  func candleBodyWidth() -> CGFloat {
    CGFloat(candleWidth)
  }

  func priceToY(_ price: Double, top: CGFloat, height: CGFloat) -> CGFloat {
    let range = priceHigh - priceLow > 0 ? priceHigh - priceLow : 1
    let normalized = CGFloat((priceHigh - price) / range)
    return top + normalized * height
  }

  func volumeToY(_ volume: Double, top: CGFloat, height: CGFloat) -> CGFloat {
    let normalized: CGFloat
    if maxVisibleVolume <= 0 {
      normalized = 0
    } else {
      normalized = CGFloat(volume / maxVisibleVolume)
    }
    return top + height - normalized * height
  }

  func applyPanDelta(
    deltaX: Double,
    candleStore: CandleStore,
    plotWidth: Double,
    config: ConfigMessage,
    chartType: String
  ) -> Bool {
    guard hasVisibleRange(), slotWidth > 0 else {
      return false
    }

    let newStart = min(
      max(0, viewportStart - (deltaX / slotWidth)),
      maxStart(candleCount: candleStore.count)
    )
    guard abs(newStart - viewportStart) > 0.0001 else {
      return false
    }

    viewportStart = newStart
    updateDerived(
      candleStore: candleStore,
      plotWidth: plotWidth,
      config: config,
      chartType: chartType
    )
    return true
  }

  func applyScale(
    scaleFactor: Double,
    focalPointX: Double,
    candleStore: CandleStore,
    plotWidth: Double,
    config: ConfigMessage,
    chartType: String
  ) -> Bool {
    guard candleStore.count > 0, plotWidth > 0 else {
      return false
    }

    if scaleBaseVisibleCount == nil {
      scaleBaseVisibleCount = visibleCountDouble
      scaleBaseStart = viewportStart
    }

    let baseVisibleCount = scaleBaseVisibleCount ?? visibleCountDouble
    let baseStart = scaleBaseStart ?? viewportStart
    let clampedScale = max(scaleFactor, 0.2)
    let newVisibleCount = min(
      Double(candleStore.count),
      min(
        Double(config.maxVisibleCandles),
        max(Double(config.minVisibleCandles), baseVisibleCount / clampedScale)
      )
    )
    let focalRatio = min(max(0, focalPointX / plotWidth), 1)
    let focalCandle = baseStart + (focalRatio * baseVisibleCount)
    let newStart = min(
      max(0, focalCandle - (focalRatio * newVisibleCount)),
      max(0, Double(candleStore.count) - newVisibleCount)
    )

    let changed = abs(newVisibleCount - visibleCountDouble) > 0.0001 || abs(newStart - viewportStart) > 0.0001
    visibleCountDouble = newVisibleCount
    viewportStart = newStart
    updateDerived(
      candleStore: candleStore,
      plotWidth: plotWidth,
      config: config,
      chartType: chartType
    )
    return changed
  }

  func endScaleGesture() {
    scaleBaseStart = nil
    scaleBaseVisibleCount = nil
  }

  func scrollToEnd(
    candleStore: CandleStore,
    plotWidth: Double,
    config: ConfigMessage,
    chartType: String
  ) -> Bool {
    guard candleStore.count > 0 else {
      return false
    }

    let newStart = maxStart(candleCount: candleStore.count)
    guard abs(newStart - viewportStart) > 0.0001 else {
      return false
    }

    viewportStart = newStart
    updateDerived(
      candleStore: candleStore,
      plotWidth: plotWidth,
      config: config,
      chartType: chartType
    )
    return true
  }

  func resolveCrosshair(
    x: Double,
    y: Double,
    contentRect: CGRect,
    mainChartRect: CGRect,
    candleStore: CandleStore
  ) -> ResolvedCrosshair? {
    guard hasVisibleRange(), slotWidth > 0 else {
      return nil
    }

    let clampedX = min(max(contentRect.minX, CGFloat(x)), contentRect.maxX)
    let clampedY = min(max(mainChartRect.minY, CGFloat(y)), mainChartRect.maxY)
    let projectedIndex = Int(
      round(viewportStart + (Double(clampedX - contentRect.minX) / slotWidth) - 0.5)
    )
    let index = min(max(visibleStartIndex, projectedIndex), visibleEndIndex)

    return ResolvedCrosshair(
      candleIndex: min(max(0, index), candleStore.count - 1),
      snappedX: xCenter(for: index, plotLeft: contentRect.minX),
      y: clampedY
    )
  }

  private func updateDerived(
    candleStore: CandleStore,
    plotWidth: Double,
    config: ConfigMessage,
    chartType: String
  ) {
    visibleStartIndex = max(0, Int(floor(viewportStart)))
    visibleEndIndex = min(candleStore.count - 1, Int(ceil(viewportStart + visibleCountDouble)) - 1)
    visibleCandleCount = max(0, visibleEndIndex - visibleStartIndex + 1)
    slotWidth = plotWidth / visibleCountDouble
    candleWidth = max(1, slotWidth * 0.72)
    isAtLatest = viewportStart >= maxStart(candleCount: candleStore.count) - 0.01
    let rangeChartType = Self.rangeChartTypeForPriceBounds(
      chartType: chartType,
      slotWidth: slotWidth
    )
    recalculateRanges(
      candleStore: candleStore,
      config: config,
      chartType: rangeChartType
    )
  }

  private static func rangeChartTypeForPriceBounds(chartType: String, slotWidth: Double) -> String {
    if chartType == "candle", slotWidth > 0, slotWidth < candleLodMaxSlotWidth {
      return "line"
    }
    return chartType
  }

  private func recalculateRanges(
    candleStore: CandleStore,
    config: ConfigMessage,
    chartType: String
  ) {
    guard hasVisibleRange() else {
      priceHigh = 0
      priceLow = 0
      maxVisibleVolume = 0
      return
    }

    var minPrice = Double.greatestFiniteMagnitude
    var maxPrice = -Double.greatestFiniteMagnitude
    var maxVolume = 0.0

    for index in visibleStartIndex...visibleEndIndex {
      let high = chartType == "line" ? candleStore.close(at: index) : candleStore.high(at: index)
      let low = chartType == "line" ? candleStore.close(at: index) : candleStore.low(at: index)
      minPrice = Swift.min(minPrice, low)
      maxPrice = Swift.max(maxPrice, high)
      maxVolume = Swift.max(maxVolume, candleStore.volume(at: index))
    }

    if minPrice == Double.greatestFiniteMagnitude || maxPrice == -Double.greatestFiniteMagnitude {
      minPrice = 0
      maxPrice = 1
    }

    if minPrice == maxPrice {
      let padding = minPrice == 0 ? 1 : minPrice * config.yAxisPaddingRatio
      minPrice -= padding
      maxPrice += padding
    } else {
      let padding = (maxPrice - minPrice) * config.yAxisPaddingRatio
      minPrice -= padding
      maxPrice += padding
    }

    priceLow = minPrice
    priceHigh = maxPrice
    maxVisibleVolume = maxVolume
  }

  private func calculateVisibleCount(
    candleCount: Int,
    plotWidth: Double,
    config: ConfigMessage
  ) -> Int {
    let idealSlotWidth = 10.0
    let estimated = max(1, Int(floor(plotWidth / idealSlotWidth)))
    let clamped = min(
      Int(config.maxVisibleCandles),
      max(Int(config.minVisibleCandles), estimated)
    )
    return min(candleCount, clamped)
  }

  private func maxStart(candleCount: Int) -> Double {
    max(0, Double(candleCount) - visibleCountDouble)
  }

  private func clear() {
    visibleStartIndex = 0
    visibleEndIndex = -1
    visibleCandleCount = 0
    candleWidth = 0
    slotWidth = 0
    priceHigh = 0
    priceLow = 0
    maxVisibleVolume = 0
    isAtLatest = true
    viewportStart = 0
    visibleCountDouble = 0
    endScaleGesture()
  }
}
