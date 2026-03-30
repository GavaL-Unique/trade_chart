package com.tradechart.plugin.renderer

import android.graphics.Path
import com.tradechart.plugin.engine.ChartFrame

class LineRenderer : ChartLayerRenderer {
    override fun render(frame: ChartFrame) {
        if (frame.chartType != "line" || !frame.viewport.hasVisibleRange()) {
            return
        }

        val chartRect = frame.mainChartRect
        val path = Path()
        for (index in frame.viewport.visibleStartIndex..frame.viewport.visibleEndIndex) {
            val centerX = frame.viewport.xCenterForIndex(index, chartRect.left)
            val y = frame.viewport.priceToY(
                frame.candleStore.closeAt(index),
                chartRect.top,
                chartRect.height(),
            )
            if (index == frame.viewport.visibleStartIndex) {
                path.moveTo(centerX, y)
            } else {
                path.lineTo(centerX, y)
            }
        }
        frame.canvas.drawPath(path, frame.theme.linePaint)
    }
}
