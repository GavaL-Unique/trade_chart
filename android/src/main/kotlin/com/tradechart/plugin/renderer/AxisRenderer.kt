package com.tradechart.plugin.renderer

import android.text.format.DateFormat
import com.tradechart.plugin.engine.ChartFrame
import java.util.Date
import kotlin.math.roundToInt

class AxisRenderer : ChartLayerRenderer {
    override fun render(frame: ChartFrame) {
        val priceAxisRect = frame.priceAxisRect
        val timeAxisRect = frame.timeAxisRect
        if (!frame.config.showAxis || priceAxisRect == null || timeAxisRect == null) {
            return
        }

        frame.canvas.drawLine(
            frame.mainChartRect.right,
            frame.mainChartRect.top,
            frame.mainChartRect.right,
            frame.mainChartRect.bottom,
            frame.theme.axisPaint,
        )
        frame.canvas.drawLine(
            frame.mainChartRect.left,
            frame.mainChartRect.bottom,
            frame.mainChartRect.right,
            frame.mainChartRect.bottom,
            frame.theme.axisPaint,
        )

        if (!frame.viewport.hasVisibleRange()) {
            return
        }

        val labelCount = 4
        for (step in 0..labelCount) {
            val ratio = step / labelCount.toFloat()
            val price = frame.viewport.priceHigh - (frame.viewport.priceHigh - frame.viewport.priceLow) * ratio
            val y = frame.mainChartRect.top + frame.mainChartRect.height() * ratio
            frame.canvas.drawText(
                formatPrice(price),
                priceAxisRect.left + 6f,
                y - 4f,
                frame.theme.axisTextPaint,
            )
        }

        val start = frame.viewport.visibleStartIndex
        val end = frame.viewport.visibleEndIndex
        val span = end - start
        val maxSlots = 5
        val slots = minOf(maxSlots, maxOf(span + 1, 1))
        val denom = maxOf(slots - 1, 1)
        val paint = frame.theme.axisTextPaint
        val plotLeft = frame.mainChartRect.left
        val vs = frame.viewport.scrollOffset
        val sw = frame.viewport.slotWidth
        val count = frame.candleStore.count
        for (step in 0 until slots) {
            val t = step.toDouble() / denom.toDouble()
            val rawIndex = start.toDouble() + span.toDouble() * t
            val idx = rawIndex.roundToInt().coerceIn(0, count - 1)
            val x = plotLeft + ((rawIndex - vs + 0.5) * sw).toFloat()
            val timestamp = frame.candleStore.timestampAt(idx)
            val label = formatTimestamp(timestamp, frame.candleStore.timeframe)
            val tw = paint.measureText(label)
            frame.canvas.drawText(
                label,
                x - tw / 2f,
                timeAxisRect.top + paint.textSize + 2f,
                paint,
            )
        }
    }

    private fun formatPrice(price: Double): String = String.format("%.2f", price)

    private fun formatTimestamp(timestamp: Long, timeframe: String): String {
        val pattern = when (timeframe) {
            "d1", "w1", "M1" -> "MM-dd"
            else -> "HH:mm"
        }
        return DateFormat.format(pattern, Date(timestamp)).toString()
    }
}
