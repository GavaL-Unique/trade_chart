package com.tradechart.plugin.engine

import android.graphics.Color
import android.graphics.PorterDuff
import android.graphics.RectF
import android.view.Choreographer
import com.tradechart.plugin.bridge.ChartFlutterApiHolder
import com.tradechart.plugin.bridge.generated.CandleDataListMessage
import com.tradechart.plugin.bridge.generated.CandleDataMessage
import com.tradechart.plugin.bridge.generated.ChartInitParams
import com.tradechart.plugin.bridge.generated.ConfigMessage
import com.tradechart.plugin.bridge.generated.CrosshairDataMessage
import com.tradechart.plugin.bridge.generated.MarkerListMessage
import com.tradechart.plugin.bridge.generated.MarkerMessage
import com.tradechart.plugin.bridge.generated.ThemeMessage
import com.tradechart.plugin.bridge.generated.ViewportStateMessage
import com.tradechart.plugin.data.CandleStore
import com.tradechart.plugin.data.MarkerStore
import com.tradechart.plugin.renderer.AxisRenderer
import com.tradechart.plugin.renderer.BackgroundRenderer
import com.tradechart.plugin.renderer.CandleRenderer
import com.tradechart.plugin.renderer.ChartLayerRenderer
import com.tradechart.plugin.renderer.CrosshairRenderer
import com.tradechart.plugin.renderer.GridRenderer
import com.tradechart.plugin.renderer.LineRenderer
import com.tradechart.plugin.renderer.MarkerRenderer
import com.tradechart.plugin.renderer.VolumeRenderer
import com.tradechart.plugin.theme.NativeChartTheme
import com.tradechart.plugin.viewport.ViewportCalculator
import io.flutter.view.TextureRegistry

class ChartEngine(
    textureRegistry: TextureRegistry,
    private val flutterApiHolder: ChartFlutterApiHolder,
) {
    private val choreographer = Choreographer.getInstance()
    private val candleStore = CandleStore()
    private val markerStore = MarkerStore()
    private val viewport = ViewportCalculator()
    private val textureRenderer = TextureRenderer(textureRegistry)
    private val renderers: List<ChartLayerRenderer> = listOf(
        BackgroundRenderer(),
        GridRenderer(),
        VolumeRenderer(),
        CandleRenderer(),
        LineRenderer(),
        MarkerRenderer(),
        AxisRenderer(),
        CrosshairRenderer(),
    )

    private lateinit var theme: NativeChartTheme
    private lateinit var config: ConfigMessage
    private var chartType: String = "candle"
    private var width: Int = 1
    private var height: Int = 1
    private var scale: Float = 1f
    private var dirty: Boolean = false
    private var frameScheduled: Boolean = false
    private var lastFrameTimeNanos: Long = 0L
    private var viewportChangedPending: Boolean = false
    private var pendingCrosshairData: CrosshairDataMessage? = null
    private var crosshairState: CrosshairState? = null
    private var flingVelocityX: Double = 0.0
    private var flingActive: Boolean = false
    private var isDisposed: Boolean = false

    private var lastAnimFrameNanos: Long = 0L

    private val frameCallback = Choreographer.FrameCallback { frameTimeNanos ->
        onFrame(frameTimeNanos)
    }

    val textureId: Long
        get() = textureRenderer.textureId

    fun initialize(params: ChartInitParams) {
        width = params.width.toInt().coerceAtLeast(1)
        height = params.height.toInt().coerceAtLeast(1)
        scale = params.devicePixelRatio.toFloat().coerceAtLeast(1f)
        theme = NativeChartTheme(params.theme)
        config = params.config
        chartType = params.config.initialChartType
        textureRenderer.resize(width, height, scale)
        dirty = true
        renderCurrentFrame()
        flutterApiHolder.onChartReady()
        flutterApiHolder.onViewportChanged(viewportState())
    }

    fun dispose() {
        isDisposed = true
        if (frameScheduled) {
            choreographer.removeFrameCallback(frameCallback)
            frameScheduled = false
        }
        textureRenderer.release()
    }

    fun onSizeChanged(width: Double, height: Double) {
        this.width = width.toInt().coerceAtLeast(1)
        this.height = height.toInt().coerceAtLeast(1)
        textureRenderer.resize(this.width, this.height, scale)
        recomputeViewport()
        markDirty(viewportChanged = candleStore.count > 0)
    }

    fun loadCandles(data: CandleDataListMessage) {
        candleStore.load(data)
        recomputeViewport()
        markDirty(viewportChanged = true)
    }

    fun appendCandle(candle: CandleDataMessage) {
        val previousCount = candleStore.count
        val lastTimestamp = candleStore.lastTimestampOrNull()
        if (lastTimestamp != null && candle.timestamp <= lastTimestamp) {
            return
        }
        val wasAtLatest = viewport.isAtLatest
        candleStore.append(candle)
        recomputeViewportForAppend(wasAtLatest, previousCount == 0)
        val viewportChanged = previousCount == 0 || (wasAtLatest && config.autoScrollOnAppend)
        markDirty(viewportChanged = viewportChanged)
    }

    fun updateLastCandle(candle: CandleDataMessage) {
        val lastTimestamp = candleStore.lastTimestampOrNull()
        if (lastTimestamp != null && candle.timestamp != lastTimestamp) {
            return
        }
        val lastWasVisible = candleStore.count == 0 ||
            (viewport.hasVisibleRange() && viewport.visibleEndIndex == candleStore.count - 1)
        candleStore.updateLast(candle)
        if (lastWasVisible) {
            recomputeViewport()
        }
        markDirty(viewportChanged = lastWasVisible)
    }

    fun setMarkers(markers: MarkerListMessage) {
        if (markers.markers.isEmpty() && candleStore.count == 0) {
            markerStore.set(emptyList())
            return
        }
        markerStore.set(markers.markers)
        markDirty()
    }

    fun addMarker(marker: MarkerMessage) {
        markerStore.add(marker)
        markDirty()
    }

    fun clearMarkers() {
        if (candleStore.count == 0) {
            markerStore.clear()
            return
        }
        markerStore.clear()
        markDirty()
    }

    fun setChartType(chartType: String) {
        this.chartType = chartType
        recomputeViewport()
        markDirty(viewportChanged = candleStore.count > 0)
    }

    fun setTimeframe(timeframe: String) {
        candleStore.clear()
        crosshairState = null
        pendingCrosshairData = null
        endFling()
        recomputeViewport()
        dirty = true
        renderCurrentFrame()
    }

    fun setTheme(theme: ThemeMessage) {
        this.theme = NativeChartTheme(theme)
        markDirty()
    }

    fun setConfig(config: ConfigMessage) {
        this.config = config
        chartType = chartType.ifBlank { config.initialChartType }
        recomputeViewport()
        markDirty(viewportChanged = candleStore.count > 0)
    }

    fun scrollToEnd() {
        endFling()
        if (viewport.scrollToEnd(candleStore, plotWidth(), config, chartType)) {
            markDirty(viewportChanged = true)
        }
    }

    fun onPanUpdate(deltaX: Double) {
        endFling()
        if (viewport.applyPanDelta(deltaX, candleStore, plotWidth(), config, chartType)) {
            markDirty(viewportChanged = true)
        }
    }

    fun onPanEnd(velocityX: Double) {
        if (kotlin.math.abs(velocityX) < 50.0 || candleStore.count == 0) {
            endFling()
            return
        }
        flingVelocityX = velocityX
        flingActive = true
        lastFrameTimeNanos = 0L
        scheduleFrame()
    }

    fun onScaleUpdate(scaleFactor: Double, focalPointX: Double) {
        endFling()
        if (viewport.applyScale(scaleFactor, focalPointX, candleStore, plotWidth(), config, chartType)) {
            markDirty(viewportChanged = true)
        }
    }

    fun onScaleEnd() {
        viewport.endScaleGesture()
    }

    fun onCrosshairStart(x: Double, y: Double) {
        if (!config.enableCrosshair) {
            return
        }
        val layout = createLayout()
        val resolved = viewport.resolveCrosshair(
            x = x,
            y = y,
            contentRect = layout.contentRect,
            mainChartRect = layout.mainChartRect,
            candleStore = candleStore,
        ) ?: return
        crosshairState = CrosshairState(
            candleIndex = resolved.candleIndex,
            snappedX = resolved.snappedX,
            y = resolved.y,
        )
        pendingCrosshairData = crosshairDataMessage(crosshairState!!)
        markDirty()
    }

    fun onCrosshairMove(x: Double, y: Double) {
        if (!config.enableCrosshair) {
            return
        }
        val layout = createLayout()
        val resolved = viewport.resolveCrosshair(
            x = x,
            y = y,
            contentRect = layout.contentRect,
            mainChartRect = layout.mainChartRect,
            candleStore = candleStore,
        ) ?: return
        crosshairState = CrosshairState(
            candleIndex = resolved.candleIndex,
            snappedX = resolved.snappedX,
            y = resolved.y,
        )
        pendingCrosshairData = crosshairDataMessage(crosshairState!!)
        markDirty()
    }

    fun onCrosshairEnd() {
        if (crosshairState == null && pendingCrosshairData == null) {
            return
        }
        crosshairState = null
        pendingCrosshairData = null
        markDirty()
    }

    private fun recomputeViewport() {
        val layout = createLayout()
        viewport.refresh(
            candleStore = candleStore,
            plotWidth = layout.mainChartRect.width().toDouble(),
            config = config,
            chartType = chartType,
        )
    }

    private fun recomputeViewportForAppend(
        wasAtLatest: Boolean,
        isFirstCandle: Boolean,
    ) {
        if (isFirstCandle) {
            recomputeViewport()
            return
        }
        if (wasAtLatest && config.autoScrollOnAppend) {
            viewport.scrollToEnd(candleStore, plotWidth(), config, chartType)
            return
        }
        recomputeViewport()
    }

    private fun renderCurrentFrame() {
        if (isDisposed) {
            return
        }
        val layout = createLayout()
        if (candleStore.count > 0) {
            viewport.refresh(
                candleStore = candleStore,
                plotWidth = layout.mainChartRect.width().toDouble(),
                config = config,
                chartType = chartType,
            )
        }

        val renderChartType = viewport.effectiveRenderChartType(chartType)
        textureRenderer.render { canvas ->
            canvas.drawColor(Color.TRANSPARENT, PorterDuff.Mode.CLEAR)
            val frame = ChartFrame(
                canvas = canvas,
                candleStore = candleStore,
                markerStore = markerStore,
                viewport = viewport,
                theme = theme,
                config = config,
                chartType = renderChartType,
                width = width,
                height = height,
                contentRect = layout.contentRect,
                mainChartRect = layout.mainChartRect,
                volumeRect = layout.volumeRect,
                priceAxisRect = layout.priceAxisRect,
                timeAxisRect = layout.timeAxisRect,
                crosshair = crosshairState,
            )
            renderers.forEach { renderer ->
                renderer.render(frame)
            }
        }
    }

    private fun viewportState(): ViewportStateMessage {
        if (candleStore.count == 0 || !viewport.hasVisibleRange()) {
            return ViewportStateMessage(
                startTimestamp = 0,
                endTimestamp = 0,
                priceHigh = 0.0,
                priceLow = 0.0,
                visibleCandleCount = 0,
                candleWidth = 0.0,
                isAtLatest = true,
            )
        }
        return ViewportStateMessage(
            startTimestamp = candleStore.timestampAt(viewport.visibleStartIndex),
            endTimestamp = candleStore.timestampAt(viewport.visibleEndIndex),
            priceHigh = viewport.priceHigh,
            priceLow = viewport.priceLow,
            visibleCandleCount = viewport.visibleCandleCount.toLong(),
            candleWidth = viewport.candleWidth,
            isAtLatest = viewport.isAtLatest,
        )
    }

    private fun markDirty(
        viewportChanged: Boolean = false,
    ) {
        dirty = true
        if (viewportChanged) {
            viewportChangedPending = true
        }
        scheduleFrame()
    }

    private fun scheduleFrame() {
        if (frameScheduled || isDisposed) {
            return
        }
        frameScheduled = true
        choreographer.postFrameCallback(frameCallback)
    }

    private fun onFrame(frameTimeNanos: Long) {
        frameScheduled = false
        if (isDisposed) {
            return
        }

        if (flingActive) {
            updateFling(frameTimeNanos)
        } else {
            lastFrameTimeNanos = 0L
        }

        if (candleStore.isAnimating) {
            val dt = if (lastAnimFrameNanos == 0L) {
                1.0 / 60.0
            } else {
                (frameTimeNanos - lastAnimFrameNanos) / 1_000_000_000.0
            }
            lastAnimFrameNanos = frameTimeNanos
            candleStore.advanceAnimation(dt)
            dirty = true
        } else {
            lastAnimFrameNanos = 0L
        }

        if (dirty) {
            renderCurrentFrame()
            dirty = false
            if (viewportChangedPending) {
                flutterApiHolder.onViewportChanged(viewportState())
                viewportChangedPending = false
            }
            pendingCrosshairData?.let {
                flutterApiHolder.onCrosshairData(it)
                pendingCrosshairData = null
            }
        }

        if (flingActive || candleStore.isAnimating || dirty) {
            scheduleFrame()
        }
    }

    private fun updateFling(frameTimeNanos: Long) {
        if (lastFrameTimeNanos == 0L) {
            lastFrameTimeNanos = frameTimeNanos
            return
        }
        val dtSeconds = (frameTimeNanos - lastFrameTimeNanos) / 1_000_000_000.0
        lastFrameTimeNanos = frameTimeNanos
        if (dtSeconds <= 0.0) {
            return
        }
        val deltaX = flingVelocityX * dtSeconds
        val moved = viewport.applyPanDelta(deltaX, candleStore, plotWidth(), config, chartType)
        if (moved) {
            dirty = true
            viewportChangedPending = true
        }
        flingVelocityX *= kotlin.math.exp(-6.0 * dtSeconds)
        if (kotlin.math.abs(flingVelocityX) < 10.0 || !moved) {
            endFling()
        }
    }

    private fun endFling() {
        flingActive = false
        flingVelocityX = 0.0
        lastFrameTimeNanos = 0L
    }

    private fun plotWidth(): Double = createLayout().mainChartRect.width().toDouble()

    private fun crosshairDataMessage(crosshair: CrosshairState): CrosshairDataMessage {
        return CrosshairDataMessage(
            timestamp = candleStore.timestampAt(crosshair.candleIndex),
            open = candleStore.openAt(crosshair.candleIndex),
            high = candleStore.highAt(crosshair.candleIndex),
            low = candleStore.lowAt(crosshair.candleIndex),
            close = candleStore.closeAt(crosshair.candleIndex),
            volume = candleStore.volumeAt(crosshair.candleIndex),
            x = crosshair.snappedX.toDouble(),
            y = crosshair.y.toDouble(),
        )
    }

    private fun createLayout(): Layout {
        val axisWidth = if (config.showAxis) 56f else 0f
        val timeAxisHeight = if (config.showAxis) 24f else 0f
        val contentRight = width.toFloat() - axisWidth
        val contentBottom = height.toFloat() - timeAxisHeight
        val contentRect = RectF(0f, 0f, contentRight, contentBottom)

        val volumeGap = if (config.showVolume) 8f else 0f
        val volumeHeight = if (config.showVolume) {
            (contentRect.height() * config.volumeHeightRatio.toFloat()).coerceAtLeast(48f)
        } else {
            0f
        }
        val mainBottom = contentRect.bottom - volumeHeight - volumeGap
        val mainChartRect = RectF(
            contentRect.left,
            contentRect.top,
            contentRect.right,
            if (config.showVolume) mainBottom else contentRect.bottom,
        )
        val volumeRect = if (config.showVolume) {
            RectF(
                contentRect.left,
                mainChartRect.bottom + volumeGap,
                contentRect.right,
                contentRect.bottom,
            )
        } else {
            null
        }
        val priceAxisRect = if (config.showAxis) {
            RectF(contentRect.right, 0f, width.toFloat(), mainChartRect.bottom)
        } else {
            null
        }
        val timeAxisRect = if (config.showAxis) {
            RectF(0f, contentBottom, width.toFloat(), height.toFloat())
        } else {
            null
        }

        return Layout(
            contentRect = contentRect,
            mainChartRect = mainChartRect,
            volumeRect = volumeRect,
            priceAxisRect = priceAxisRect,
            timeAxisRect = timeAxisRect,
        )
    }

    private data class Layout(
        val contentRect: RectF,
        val mainChartRect: RectF,
        val volumeRect: RectF?,
        val priceAxisRect: RectF?,
        val timeAxisRect: RectF?,
    )
}
