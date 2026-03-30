package com.tradechart.plugin.bridge

import com.tradechart.plugin.bridge.generated.ChartFlutterApi
import com.tradechart.plugin.bridge.generated.CrosshairDataMessage
import com.tradechart.plugin.bridge.generated.ViewportStateMessage

class ChartFlutterApiHolder(
    private val flutterApi: ChartFlutterApi,
) {
    fun onChartReady() {
        flutterApi.onChartReady {}
    }

    fun onViewportChanged(viewport: ViewportStateMessage) {
        flutterApi.onViewportChanged(viewport) {}
    }

    fun onCrosshairData(data: CrosshairDataMessage) {
        flutterApi.onCrosshairData(data) {}
    }

    fun onError(code: String, message: String) {
        flutterApi.onError(code, message) {}
    }
}
