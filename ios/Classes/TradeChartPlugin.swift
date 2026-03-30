import Flutter
import Foundation

public class TradeChartPlugin: NSObject, FlutterPlugin {
  private var hostApiImpl: ChartHostApiImpl?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = TradeChartPlugin()
    let flutterApiHolder = ChartFlutterApiHolder(
      flutterApi: ChartFlutterApi(binaryMessenger: registrar.messenger())
    )
    instance.hostApiImpl = ChartHostApiImpl(
      textureRegistry: registrar.textures(),
      flutterApiHolder: flutterApiHolder
    )
    ChartHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance.hostApiImpl)
  }
}
