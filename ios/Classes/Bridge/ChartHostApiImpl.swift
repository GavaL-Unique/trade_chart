import Flutter
import Foundation

final class ChartHostApiImpl: ChartHostApi {
  init(textureRegistry: FlutterTextureRegistry, flutterApiHolder: ChartFlutterApiHolder) {
    self.textureRegistry = textureRegistry
    self.flutterApiHolder = flutterApiHolder
  }

  private let textureRegistry: FlutterTextureRegistry
  private let flutterApiHolder: ChartFlutterApiHolder
  private var chartEngine: ChartEngine?

  func initialize(params: ChartInitParams, completion: @escaping (Result<Int64, Error>) -> Void) {
    let engine = ChartEngine(textureRegistry: textureRegistry, flutterApiHolder: flutterApiHolder)
    engine.initialize(params: params)
    chartEngine = engine
    completion(.success(engine.textureId))
  }

  func dispose() throws {
    chartEngine?.dispose()
    chartEngine = nil
  }

  func onSizeChanged(width: Double, height: Double) throws {
    chartEngine?.onSizeChanged(width: width, height: height)
  }

  func loadCandles(data: CandleDataListMessage) throws {
    chartEngine?.loadCandles(data: data)
  }

  func appendCandle(candle: CandleDataMessage) throws {
    chartEngine?.appendCandle(candle: candle)
  }

  func updateLastCandle(candle: CandleDataMessage) throws {
    chartEngine?.updateLastCandle(candle: candle)
  }

  func setMarkers(markers: MarkerListMessage) throws {
    chartEngine?.setMarkers(markers: markers)
  }

  func addMarker(marker: MarkerMessage) throws {
    chartEngine?.addMarker(marker: marker)
  }

  func clearMarkers() throws {
    chartEngine?.clearMarkers()
  }

  func setChartType(chartType: String) throws {
    chartEngine?.setChartType(chartType: chartType)
  }

  func setTimeframe(timeframe: String) throws {
    chartEngine?.setTimeframe(timeframe: timeframe)
  }

  func setTheme(theme: ThemeMessage) throws {
    chartEngine?.setTheme(theme: theme)
  }

  func setConfig(config: ConfigMessage) throws {
    chartEngine?.setConfig(config: config)
  }

  func scrollToEnd() throws {
    chartEngine?.scrollToEnd()
  }

  func onPanUpdate(deltaX: Double) throws {
    chartEngine?.onPanUpdate(deltaX: deltaX)
  }

  func onPanEnd(velocityX: Double) throws {
    chartEngine?.onPanEnd(velocityX: velocityX)
  }

  func onScaleUpdate(scaleFactor: Double, focalPointX: Double) throws {
    chartEngine?.onScaleUpdate(scaleFactor: scaleFactor, focalPointX: focalPointX)
  }

  func onScaleEnd() throws {
    chartEngine?.onScaleEnd()
  }

  func onCrosshairStart(x: Double, y: Double) throws {
    chartEngine?.onCrosshairStart(x: x, y: y)
  }

  func onCrosshairMove(x: Double, y: Double) throws {
    chartEngine?.onCrosshairMove(x: x, y: y)
  }

  func onCrosshairEnd() throws {
    chartEngine?.onCrosshairEnd()
  }
}
