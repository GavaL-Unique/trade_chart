package com.tradechart.plugin.viewport

import android.graphics.RectF
import com.tradechart.plugin.bridge.generated.ConfigMessage
import com.tradechart.plugin.data.CandleStore
import kotlin.math.ceil
import kotlin.math.floor
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

/** Below this slot width (logical px), candle mode draws as a close line (Bybit-style LOD). */
private const val CANDLE_LOD_MAX_SLOT_WIDTH = 4.0

data class ResolvedCrosshair(
    val candleIndex: Int,
    val snappedX: Float,
    val y: Float,
)

class ViewportCalculator {
    var visibleStartIndex: Int = 0
        private set
    var visibleEndIndex: Int = -1
        private set
    var visibleCandleCount: Int = 0
        private set
    var candleWidth: Double = 0.0
        private set
    var slotWidth: Double = 0.0
        private set
    var priceHigh: Double = 0.0
        private set
    var priceLow: Double = 0.0
        private set
    var maxVisibleVolume: Double = 0.0
        private set
    var isAtLatest: Boolean = true
        private set

    private var viewportStart: Double = 0.0
    private var visibleCountDouble: Double = 0.0

    val scrollOffset: Double
        get() = viewportStart
    private var scaleBaseStart: Double? = null
    private var scaleBaseVisibleCount: Double? = null

    private fun rangeChartTypeForPriceBounds(chartType: String, slotWidth: Double): String {
        if (chartType == "candle" && slotWidth > 0.0 && slotWidth < CANDLE_LOD_MAX_SLOT_WIDTH) {
            return "line"
        }
        return chartType
    }

    fun resetToLatest(
        candleStore: CandleStore,
        plotWidth: Double,
        config: ConfigMessage,
        chartType: String,
    ) {
        if (candleStore.count == 0 || plotWidth <= 0.0) {
            clear()
            return
        }
        visibleCountDouble = calculateVisibleCount(
            candleCount = candleStore.count,
            plotWidth = plotWidth,
            config = config,
        ).toDouble()
        viewportStart = maxStart(candleStore.count)
        updateDerived(candleStore, plotWidth, config, chartType)
    }

    fun refresh(
        candleStore: CandleStore,
        plotWidth: Double,
        config: ConfigMessage,
        chartType: String,
    ) {
        if (candleStore.count == 0 || plotWidth <= 0.0) {
            clear()
            return
        }
        if (visibleCountDouble <= 0.0) {
            resetToLatest(candleStore, plotWidth, config, chartType)
            return
        }
        visibleCountDouble = visibleCountDouble
            .coerceAtLeast(config.minVisibleCandles.toDouble())
            .coerceAtMost(config.maxVisibleCandles.toDouble())
            .coerceAtMost(candleStore.count.toDouble())
        viewportStart = viewportStart.coerceIn(0.0, maxStart(candleStore.count))
        updateDerived(candleStore, plotWidth, config, chartType)
    }

    fun hasVisibleRange(): Boolean {
        return visibleCandleCount > 0 && visibleEndIndex >= visibleStartIndex
    }

    fun effectiveRenderChartType(userChartType: String): String {
        return rangeChartTypeForPriceBounds(userChartType, slotWidth)
    }

    fun candleIndexAtVisibleRatio(t: Double, candleCount: Int): Int {
        if (!hasVisibleRange() || candleCount <= 0 || visibleCountDouble <= 0.0) {
            return 0
        }
        val u = t.coerceIn(0.0, 1.0)
        val raw = viewportStart + u * visibleCountDouble - 0.5
        val idx = raw.roundToInt()
        return idx.coerceIn(0, candleCount - 1)
    }

    fun xCenterForIndex(index: Int, plotLeft: Float): Float {
        return plotLeft + ((index - viewportStart) + 0.5) .toFloat() * slotWidth.toFloat()
    }

    fun candleBodyWidth(): Float = candleWidth.toFloat()

    fun priceToY(price: Double, top: Float, height: Float): Float {
        val range = (priceHigh - priceLow).takeIf { it > 0.0 } ?: 1.0
        val normalized = ((priceHigh - price) / range).toFloat()
        return top + normalized * height
    }

    fun volumeToY(volume: Double, top: Float, height: Float): Float {
        val normalized = if (maxVisibleVolume <= 0.0) {
            0.0f
        } else {
            (volume / maxVisibleVolume).toFloat()
        }
        return top + height - normalized * height
    }

    fun applyPanDelta(
        deltaX: Double,
        candleStore: CandleStore,
        plotWidth: Double,
        config: ConfigMessage,
        chartType: String,
    ): Boolean {
        if (!hasVisibleRange() || slotWidth <= 0.0) {
            return false
        }
        val newStart = (viewportStart - (deltaX / slotWidth)).coerceIn(0.0, maxStart(candleStore.count))
        if (newStart == viewportStart) {
            return false
        }
        viewportStart = newStart
        updateDerived(candleStore, plotWidth, config, chartType)
        return true
    }

    fun applyScale(
        scaleFactor: Double,
        focalPointX: Double,
        candleStore: CandleStore,
        plotWidth: Double,
        config: ConfigMessage,
        chartType: String,
    ): Boolean {
        if (candleStore.count == 0 || plotWidth <= 0.0) {
            return false
        }
        val baseVisibleCount = scaleBaseVisibleCount ?: visibleCountDouble.also {
            scaleBaseVisibleCount = it
            scaleBaseStart = viewportStart
        }
        val baseStart = scaleBaseStart ?: viewportStart
        val clampedScale = scaleFactor.coerceAtLeast(0.2)
        val newVisibleCount = (baseVisibleCount / clampedScale)
            .coerceAtLeast(config.minVisibleCandles.toDouble())
            .coerceAtMost(config.maxVisibleCandles.toDouble())
            .coerceAtMost(candleStore.count.toDouble())
        val focalRatio = (focalPointX / plotWidth).coerceIn(0.0, 1.0)
        val focalCandle = baseStart + focalRatio * baseVisibleCount
        val newStart = (focalCandle - focalRatio * newVisibleCount).coerceIn(
            0.0,
            max(0.0, candleStore.count - newVisibleCount),
        )
        val changed = newVisibleCount != visibleCountDouble || newStart != viewportStart
        visibleCountDouble = newVisibleCount
        viewportStart = newStart
        updateDerived(candleStore, plotWidth, config, chartType)
        return changed
    }

    fun endScaleGesture() {
        scaleBaseStart = null
        scaleBaseVisibleCount = null
    }

    fun scrollToEnd(
        candleStore: CandleStore,
        plotWidth: Double,
        config: ConfigMessage,
        chartType: String,
    ): Boolean {
        if (candleStore.count == 0) {
            return false
        }
        val newStart = maxStart(candleStore.count)
        if (newStart == viewportStart) {
            return false
        }
        viewportStart = newStart
        updateDerived(candleStore, plotWidth, config, chartType)
        return true
    }

    fun resolveCrosshair(
        x: Double,
        y: Double,
        contentRect: RectF,
        mainChartRect: RectF,
        candleStore: CandleStore,
    ): ResolvedCrosshair? {
        if (!hasVisibleRange() || slotWidth <= 0.0) {
            return null
        }
        val clampedX = x.coerceIn(contentRect.left.toDouble(), contentRect.right.toDouble())
        val clampedY = y.coerceIn(mainChartRect.top.toDouble(), mainChartRect.bottom.toDouble())
        val index = (viewportStart + ((clampedX - contentRect.left) / slotWidth) - 0.5)
            .roundToInt()
            .coerceIn(visibleStartIndex, visibleEndIndex)
        return ResolvedCrosshair(
            candleIndex = index.coerceIn(0, candleStore.count - 1),
            snappedX = xCenterForIndex(index, contentRect.left),
            y = clampedY.toFloat(),
        )
    }

    private fun updateDerived(
        candleStore: CandleStore,
        plotWidth: Double,
        config: ConfigMessage,
        chartType: String,
    ) {
        visibleStartIndex = floor(viewportStart).toInt().coerceAtLeast(0)
        visibleEndIndex = min(
            candleStore.count - 1,
            ceil(viewportStart + visibleCountDouble).toInt() - 1,
        )
        visibleCandleCount = max(0, visibleEndIndex - visibleStartIndex + 1)
        slotWidth = plotWidth / visibleCountDouble
        candleWidth = max(1.0, slotWidth * 0.72)
        isAtLatest = viewportStart >= maxStart(candleStore.count) - 0.01
        val rangeChartType = rangeChartTypeForPriceBounds(chartType, slotWidth)
        recalculateRanges(candleStore, config, rangeChartType)
    }

    private fun recalculateRanges(
        candleStore: CandleStore,
        config: ConfigMessage,
        chartType: String,
    ) {
        if (!hasVisibleRange()) {
            priceHigh = 0.0
            priceLow = 0.0
            maxVisibleVolume = 0.0
            return
        }

        var minPrice = Double.POSITIVE_INFINITY
        var maxPrice = Double.NEGATIVE_INFINITY
        var maxVolume = 0.0

        for (index in visibleStartIndex..visibleEndIndex) {
            val high = if (chartType == "line") candleStore.closeAt(index) else candleStore.highAt(index)
            val low = if (chartType == "line") candleStore.closeAt(index) else candleStore.lowAt(index)
            minPrice = min(minPrice, low)
            maxPrice = max(maxPrice, high)
            maxVolume = max(maxVolume, candleStore.volumeAt(index))
        }

        if (minPrice == Double.POSITIVE_INFINITY || maxPrice == Double.NEGATIVE_INFINITY) {
            minPrice = 0.0
            maxPrice = 1.0
        }
        if (minPrice == maxPrice) {
            val fallbackPadding = if (minPrice == 0.0) 1.0 else minPrice * config.yAxisPaddingRatio
            minPrice -= fallbackPadding
            maxPrice += fallbackPadding
        } else {
            val padding = (maxPrice - minPrice) * config.yAxisPaddingRatio
            minPrice -= padding
            maxPrice += padding
        }

        priceLow = minPrice
        priceHigh = maxPrice
        maxVisibleVolume = maxVolume
    }

    private fun calculateVisibleCount(
        candleCount: Int,
        plotWidth: Double,
        config: ConfigMessage,
    ): Int {
        val idealSlotWidth = 10.0
        val estimatedCount = floor(plotWidth / idealSlotWidth).toInt().coerceAtLeast(1)
        val clamped = estimatedCount
            .coerceAtLeast(config.minVisibleCandles.toInt())
            .coerceAtMost(config.maxVisibleCandles.toInt())
        return min(candleCount, clamped)
    }

    private fun maxStart(candleCount: Int): Double {
        return max(0.0, candleCount.toDouble() - visibleCountDouble)
    }

    private fun clear() {
        visibleStartIndex = 0
        visibleEndIndex = -1
        visibleCandleCount = 0
        candleWidth = 0.0
        slotWidth = 0.0
        priceHigh = 0.0
        priceLow = 0.0
        maxVisibleVolume = 0.0
        isAtLatest = true
        viewportStart = 0.0
        visibleCountDouble = 0.0
        endScaleGesture()
    }
}
