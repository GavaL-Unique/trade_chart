package com.tradechart.plugin.renderer

import com.tradechart.plugin.engine.ChartFrame

fun interface ChartLayerRenderer {
    fun render(frame: ChartFrame)
}
