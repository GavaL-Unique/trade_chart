package com.tradechart.plugin.renderer

import com.tradechart.plugin.engine.ChartFrame

class BackgroundRenderer : ChartLayerRenderer {
    override fun render(frame: ChartFrame) {
        frame.canvas.drawRect(
            0f,
            0f,
            frame.width.toFloat(),
            frame.height.toFloat(),
            frame.theme.backgroundPaint,
        )
    }
}
