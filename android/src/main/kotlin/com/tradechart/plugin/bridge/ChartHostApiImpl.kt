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
    private var chartEngine: ChartEngine? = null

    override fun initialize(params: ChartInitParams, callback: (Result<Long>) -> Unit) {
        try {
            chartEngine?.dispose()
            val engine = ChartEngine(
                textureRegistry = textureRegistry,
                flutterApiHolder = flutterApiHolder,
            )
            engine.initialize(params)
            chartEngine = engine
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

    override fun dispose() {
        chartEngine?.dispose()
        chartEngine = null
    }

    override fun onSizeChanged(width: Double, height: Double) {
        chartEngine?.onSizeChanged(width, height)
    }

    override fun loadCandles(data: CandleDataListMessage) {
        chartEngine?.loadCandles(data)
    }

    override fun appendCandle(candle: CandleDataMessage) {
        chartEngine?.appendCandle(candle)
    }

    override fun updateLastCandle(candle: CandleDataMessage) {
        chartEngine?.updateLastCandle(candle)
    }

    override fun setMarkers(markers: MarkerListMessage) {
        chartEngine?.setMarkers(markers)
    }

    override fun addMarker(marker: MarkerMessage) {
        chartEngine?.addMarker(marker)
    }

    override fun clearMarkers() {
        chartEngine?.clearMarkers()
    }

    override fun setChartType(chartType: String) {
        chartEngine?.setChartType(chartType)
    }

    override fun setTimeframe(timeframe: String) {
        chartEngine?.setTimeframe(timeframe)
    }

    override fun setTheme(theme: ThemeMessage) {
        chartEngine?.setTheme(theme)
    }

    override fun setConfig(config: ConfigMessage) {
        chartEngine?.setConfig(config)
    }

    override fun scrollToEnd() {
        chartEngine?.scrollToEnd()
    }

    override fun onPanUpdate(deltaX: Double) {
        chartEngine?.onPanUpdate(deltaX)
    }

    override fun onPanEnd(velocityX: Double) {
        chartEngine?.onPanEnd(velocityX)
    }

    override fun onScaleUpdate(scaleFactor: Double, focalPointX: Double) {
        chartEngine?.onScaleUpdate(scaleFactor, focalPointX)
    }

    override fun onScaleEnd() {
        chartEngine?.onScaleEnd()
    }

    override fun onCrosshairStart(x: Double, y: Double) {
        chartEngine?.onCrosshairStart(x, y)
    }

    override fun onCrosshairMove(x: Double, y: Double) {
        chartEngine?.onCrosshairMove(x, y)
    }

    override fun onCrosshairEnd() {
        chartEngine?.onCrosshairEnd()
    }
}
