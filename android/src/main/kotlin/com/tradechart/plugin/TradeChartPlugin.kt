package com.tradechart.plugin

import com.tradechart.plugin.bridge.ChartFlutterApiHolder
import com.tradechart.plugin.bridge.ChartHostApiImpl
import com.tradechart.plugin.bridge.generated.ChartFlutterApi
import com.tradechart.plugin.bridge.generated.ChartHostApi
import io.flutter.embedding.engine.plugins.FlutterPlugin

class TradeChartPlugin : FlutterPlugin {
    private var hostApiImpl: ChartHostApiImpl? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val flutterApiHolder = ChartFlutterApiHolder(ChartFlutterApi(binding.binaryMessenger))
        hostApiImpl = ChartHostApiImpl(
            textureRegistry = binding.textureRegistry,
            flutterApiHolder = flutterApiHolder,
        )
        ChartHostApi.setUp(binding.binaryMessenger, hostApiImpl)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        hostApiImpl?.dispose()
        hostApiImpl = null
        ChartHostApi.setUp(binding.binaryMessenger, null)
    }
}
