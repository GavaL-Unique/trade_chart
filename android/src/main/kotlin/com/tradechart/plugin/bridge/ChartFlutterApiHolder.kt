package com.tradechart.plugin.bridge

import com.tradechart.plugin.bridge.generated.ChartFlutterApi
import com.tradechart.plugin.bridge.generated.CrosshairDataMessage
import com.tradechart.plugin.bridge.generated.ViewportStateMessage

class ChartFlutterApiHolder(
    private val flutterApi: ChartFlutterApi,
) {
    fun onChartReady(chartId: Long) {
        flutterApi.onChartReady(chartId) {}
    }

    fun onViewportChanged(chartId: Long, viewport: ViewportStateMessage) {
        flutterApi.onViewportChanged(chartId, viewport) {}
    }

    fun onCrosshairData(chartId: Long, data: CrosshairDataMessage) {
        flutterApi.onCrosshairData(chartId, data) {}
    }

    fun onError(chartId: Long, code: String, message: String) {
        flutterApi.onError(chartId, code, message) {}
    }
}
