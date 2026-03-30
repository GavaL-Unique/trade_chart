package com.tradechart.plugin.renderer

import android.graphics.RectF
import android.text.format.DateFormat
import com.tradechart.plugin.engine.ChartFrame
import java.util.Date

class CrosshairRenderer : ChartLayerRenderer {
    override fun render(frame: ChartFrame) {
        val crosshair = frame.crosshair ?: return
        val priceAxisRect = frame.priceAxisRect
        val timeAxisRect = frame.timeAxisRect

        frame.canvas.drawLine(
            crosshair.snappedX,
            frame.contentRect.top,
            crosshair.snappedX,
            frame.contentRect.bottom,
            frame.theme.crosshairPaint,
        )
        frame.canvas.drawLine(
            frame.mainChartRect.left,
            crosshair.y,
            frame.mainChartRect.right,
            crosshair.y,
            frame.theme.crosshairPaint,
        )

        if (priceAxisRect != null) {
            val price = priceAtCrosshairY(frame, crosshair.y)
            val text = String.format("%.2f", price)
            val textWidth = frame.theme.crosshairTextPaint.measureText(text)
            val labelRect = RectF(
                priceAxisRect.left + 4f,
                crosshair.y - frame.theme.crosshairTextPaint.textSize,
                priceAxisRect.left + 12f + textWidth,
                crosshair.y + 6f,
            )
            frame.canvas.drawRoundRect(labelRect, 6f, 6f, frame.theme.crosshairLabelBackgroundPaint)
            frame.canvas.drawText(
                text,
                labelRect.left + 4f,
                labelRect.bottom - 6f,
                frame.theme.crosshairTextPaint,
            )
        }

        if (timeAxisRect != null) {
            val timestamp = frame.candleStore.timestampAt(crosshair.candleIndex)
            val text = DateFormat.format(timePattern(frame.candleStore.timeframe), Date(timestamp)).toString()
            val textWidth = frame.theme.crosshairTextPaint.measureText(text)
            val labelRect = RectF(
                crosshair.snappedX - textWidth / 2f - 8f,
                timeAxisRect.top + 2f,
                crosshair.snappedX + textWidth / 2f + 8f,
                timeAxisRect.top + frame.theme.crosshairTextPaint.textSize + 10f,
            )
            frame.canvas.drawRoundRect(labelRect, 6f, 6f, frame.theme.crosshairLabelBackgroundPaint)
            frame.canvas.drawText(
                text,
                labelRect.left + 4f,
                labelRect.bottom - 6f,
                frame.theme.crosshairTextPaint,
            )
        }
    }

    private fun priceAtCrosshairY(frame: ChartFrame, y: Float): Double {
        val ratio = ((y - frame.mainChartRect.top) / frame.mainChartRect.height()).coerceIn(0f, 1f)
        return frame.viewport.priceHigh - (frame.viewport.priceHigh - frame.viewport.priceLow) * ratio
    }

    private fun timePattern(timeframe: String): String {
        return when (timeframe) {
            "d1", "w1", "M1" -> "MM-dd"
            else -> "HH:mm"
        }
    }
}
