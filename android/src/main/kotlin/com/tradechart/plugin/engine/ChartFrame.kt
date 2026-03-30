package com.tradechart.plugin.engine

import android.graphics.Canvas
import android.graphics.RectF
import com.tradechart.plugin.bridge.generated.ConfigMessage
import com.tradechart.plugin.data.CandleStore
import com.tradechart.plugin.data.MarkerStore
import com.tradechart.plugin.theme.NativeChartTheme
import com.tradechart.plugin.viewport.ViewportCalculator

data class CrosshairState(
    val candleIndex: Int,
    val snappedX: Float,
    val y: Float,
)

data class ChartFrame(
    val canvas: Canvas,
    val candleStore: CandleStore,
    val markerStore: MarkerStore,
    val viewport: ViewportCalculator,
    val theme: NativeChartTheme,
    val config: ConfigMessage,
    val chartType: String,
    val width: Int,
    val height: Int,
    val contentRect: RectF,
    val mainChartRect: RectF,
    val volumeRect: RectF?,
    val priceAxisRect: RectF?,
    val timeAxisRect: RectF?,
    val crosshair: CrosshairState?,
)
