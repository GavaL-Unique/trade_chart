package com.tradechart.plugin.renderer

import android.graphics.Path
import android.graphics.RectF
import com.tradechart.plugin.engine.ChartFrame

class MarkerRenderer : ChartLayerRenderer {
    override fun render(frame: ChartFrame) {
        if (!frame.viewport.hasVisibleRange()) {
            return
        }

        val visibleMarkers = frame.markerStore.visibleMarkers(
            startTimestamp = frame.candleStore.timestampAt(frame.viewport.visibleStartIndex),
            endTimestamp = frame.candleStore.timestampAt(frame.viewport.visibleEndIndex),
        )
        if (visibleMarkers.isEmpty()) {
            return
        }

        for (marker in visibleMarkers) {
            val candleIndex = frame.candleStore.indexOfTimestamp(marker.timestamp)
            if (candleIndex !in frame.viewport.visibleStartIndex..frame.viewport.visibleEndIndex) {
                continue
            }
            val x = frame.viewport.xCenterForIndex(candleIndex, frame.mainChartRect.left)
            val y = frame.viewport.priceToY(
                price = marker.price,
                top = frame.mainChartRect.top,
                height = frame.mainChartRect.height(),
            )
            if (y < frame.mainChartRect.top - 24f || y > frame.mainChartRect.bottom + 24f) {
                continue
            }

            val isBuy = marker.type == "buy"
            val trianglePath = Path().apply {
                if (isBuy) {
                    moveTo(x, y - 10f)
                    lineTo(x - 8f, y + 4f)
                    lineTo(x + 8f, y + 4f)
                } else {
                    moveTo(x, y + 10f)
                    lineTo(x - 8f, y - 4f)
                    lineTo(x + 8f, y - 4f)
                }
                close()
            }
            frame.canvas.drawPath(
                trianglePath,
                if (isBuy) frame.theme.buyMarkerPaint else frame.theme.sellMarkerPaint,
            )

            marker.label?.takeIf { it.isNotBlank() }?.let { label ->
                val textWidth = frame.theme.markerTextPaint.measureText(label)
                val labelTop = if (isBuy) y + 8f else y - frame.theme.markerTextPaint.textSize - 16f
                val labelRect = RectF(
                    x - textWidth / 2f - 6f,
                    labelTop,
                    x + textWidth / 2f + 6f,
                    labelTop + frame.theme.markerTextPaint.textSize + 8f,
                )
                frame.canvas.drawRoundRect(
                    labelRect,
                    6f,
                    6f,
                    frame.theme.crosshairLabelBackgroundPaint,
                )
                frame.canvas.drawText(
                    label,
                    labelRect.left + 6f,
                    labelRect.bottom - 6f,
                    frame.theme.markerTextPaint,
                )
            }
        }
    }
}
