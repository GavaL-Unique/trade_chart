package com.tradechart.plugin.renderer

import android.graphics.RectF
import com.tradechart.plugin.engine.ChartFrame
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min

class CandleRenderer : ChartLayerRenderer {
    override fun render(frame: ChartFrame) {
        if (frame.chartType != "candle" || !frame.viewport.hasVisibleRange()) {
            return
        }

        val chartRect = frame.mainChartRect
        val bodyWidth = max(1f, frame.viewport.candleBodyWidth())

        for (index in frame.viewport.visibleStartIndex..frame.viewport.visibleEndIndex) {
            val open = frame.candleStore.openAt(index)
            val close = frame.candleStore.closeAt(index)
            val high = frame.candleStore.highAt(index)
            val low = frame.candleStore.lowAt(index)
            val centerX = frame.viewport.xCenterForIndex(index, chartRect.left)
            val openY = frame.viewport.priceToY(open, chartRect.top, chartRect.height())
            val closeY = frame.viewport.priceToY(close, chartRect.top, chartRect.height())
            val highY = frame.viewport.priceToY(high, chartRect.top, chartRect.height())
            val lowY = frame.viewport.priceToY(low, chartRect.top, chartRect.height())

            val isBull = close >= open
            val bodyPaint = if (isBull) frame.theme.bullPaint else frame.theme.bearPaint
            val wickPaint = if (isBull) frame.theme.bullWickPaint else frame.theme.bearWickPaint

            frame.canvas.drawLine(centerX, highY, centerX, lowY, wickPaint)

            val bodyTop = min(openY, closeY)
            val bodyBottom = max(openY, closeY)
            val adjustedBottom = if (abs(bodyBottom - bodyTop) < 1f) bodyTop + 1f else bodyBottom
            frame.canvas.drawRect(
                RectF(
                    centerX - bodyWidth / 2f,
                    bodyTop,
                    centerX + bodyWidth / 2f,
                    adjustedBottom,
                ),
                bodyPaint,
            )
        }
    }
}
