package com.tradechart.plugin.renderer

import com.tradechart.plugin.engine.ChartFrame

class GridRenderer : ChartLayerRenderer {
    override fun render(frame: ChartFrame) {
        if (!frame.config.showGrid) {
            return
        }

        val main = frame.mainChartRect
        val volume = frame.volumeRect
        val horizontalLines = 4
        for (step in 0..horizontalLines) {
            val y = main.top + (main.height() / horizontalLines) * step
            frame.canvas.drawLine(main.left, y, main.right, y, frame.theme.gridPaint)
        }

        if (volume != null) {
            frame.canvas.drawLine(volume.left, volume.top, volume.right, volume.top, frame.theme.gridPaint)
            frame.canvas.drawLine(volume.left, volume.bottom, volume.right, volume.bottom, frame.theme.gridPaint)
        }

        val verticalLines = 4
        for (step in 0..verticalLines) {
            val x = main.left + (main.width() / verticalLines) * step
            frame.canvas.drawLine(main.left.coerceAtMost(x), main.top, x, main.bottom, frame.theme.gridPaint)
            if (volume != null) {
                frame.canvas.drawLine(x, volume.top, x, volume.bottom, frame.theme.gridPaint)
            }
        }
    }
}
