package com.tradechart.plugin.bridge

import com.tradechart.plugin.bridge.generated.CandleDataListMessage
import com.tradechart.plugin.bridge.generated.CandleDataMessage
import com.tradechart.plugin.bridge.generated.ChartHostApi
import com.tradechart.plugin.bridge.generated.ChartInitParams
import com.tradechart.plugin.bridge.generated.ConfigMessage
import com.tradechart.plugin.bridge.generated.FlutterError
import com.tradechart.plugin.bridge.generated.MarkerListMessage
import com.tradechart.plugin.bridge.generated.MarkerMessage
import com.tradechart.plugin.bridge.generated.ThemeMessage
import com.tradechart.plugin.engine.ChartEngine
import io.flutter.view.TextureRegistry

class ChartHostApiImpl(
    private val textureRegistry: TextureRegistry,
    private val flutterApiHolder: ChartFlutterApiHolder,
) : ChartHostApi {
    private val chartEngines = mutableMapOf<Long, ChartEngine>()

    override fun initialize(params: ChartInitParams, callback: (Result<Long>) -> Unit) {
        try {
            chartEngines.remove(params.chartId)?.dispose()
            val engine = ChartEngine(
                chartId = params.chartId,
                textureRegistry = textureRegistry,
                flutterApiHolder = flutterApiHolder,
            )
            engine.initialize(params)
            chartEngines[params.chartId] = engine
            callback(Result.success(engine.textureId))
        } catch (throwable: Throwable) {
            callback(
                Result.failure(
                    FlutterError(
                        "TEXTURE_ALLOC_FAILED",
                        throwable.message ?: "Failed to initialize texture renderer.",
                        null,
                    ),
                ),
            )
        }
    }

    override fun dispose(chartId: Long) {
        chartEngines.remove(chartId)?.dispose()
    }

    override fun onSizeChanged(chartId: Long, width: Double, height: Double) {
        chartEngines[chartId]?.onSizeChanged(width, height)
    }

    override fun loadCandles(chartId: Long, data: CandleDataListMessage) {
        chartEngines[chartId]?.loadCandles(data)
    }

    override fun appendCandle(chartId: Long, candle: CandleDataMessage) {
        chartEngines[chartId]?.appendCandle(candle)
    }

    override fun updateLastCandle(chartId: Long, candle: CandleDataMessage) {
        chartEngines[chartId]?.updateLastCandle(candle)
    }

    override fun setMarkers(chartId: Long, markers: MarkerListMessage) {
        chartEngines[chartId]?.setMarkers(markers)
    }

    override fun addMarker(chartId: Long, marker: MarkerMessage) {
        chartEngines[chartId]?.addMarker(marker)
    }

    override fun clearMarkers(chartId: Long) {
        chartEngines[chartId]?.clearMarkers()
    }

    override fun setChartType(chartId: Long, chartType: String) {
        chartEngines[chartId]?.setChartType(chartType)
    }

    override fun setTimeframe(chartId: Long, timeframe: String) {
        chartEngines[chartId]?.setTimeframe(timeframe)
    }

    override fun setTheme(chartId: Long, theme: ThemeMessage) {
        chartEngines[chartId]?.setTheme(theme)
    }

    override fun setConfig(chartId: Long, config: ConfigMessage) {
        chartEngines[chartId]?.setConfig(config)
    }

    override fun scrollToEnd(chartId: Long) {
        chartEngines[chartId]?.scrollToEnd()
    }

    override fun onPanUpdate(chartId: Long, deltaX: Double) {
        chartEngines[chartId]?.onPanUpdate(deltaX)
    }

    override fun onPanEnd(chartId: Long, velocityX: Double) {
        chartEngines[chartId]?.onPanEnd(velocityX)
    }

    override fun onScaleUpdate(chartId: Long, scaleFactor: Double, focalPointX: Double) {
        chartEngines[chartId]?.onScaleUpdate(scaleFactor, focalPointX)
    }

    override fun onScaleEnd(chartId: Long) {
        chartEngines[chartId]?.onScaleEnd()
    }

    override fun onCrosshairStart(chartId: Long, x: Double, y: Double) {
        chartEngines[chartId]?.onCrosshairStart(x, y)
    }

    override fun onCrosshairMove(chartId: Long, x: Double, y: Double) {
        chartEngines[chartId]?.onCrosshairMove(x, y)
    }

    override fun onCrosshairEnd(chartId: Long) {
        chartEngines[chartId]?.onCrosshairEnd()
    }
}
