import Flutter
import Foundation

final class ChartHostApiImpl: ChartHostApi {
  init(textureRegistry: FlutterTextureRegistry, flutterApiHolder: ChartFlutterApiHolder) {
    self.textureRegistry = textureRegistry
    self.flutterApiHolder = flutterApiHolder
  }

  private let textureRegistry: FlutterTextureRegistry
  private let flutterApiHolder: ChartFlutterApiHolder
  private var chartEngines: [Int64: ChartEngine] = [:]

  func initialize(params: ChartInitParams, completion: @escaping (Result<Int64, Error>) -> Void) {
    chartEngines[params.chartId]?.dispose()
    let engine = ChartEngine(
      chartId: params.chartId,
      textureRegistry: textureRegistry,
      flutterApiHolder: flutterApiHolder
    )
    engine.initialize(params: params)
    chartEngines[params.chartId] = engine
    completion(.success(engine.textureId))
  }

  func dispose(chartId: Int64) throws {
    chartEngines.removeValue(forKey: chartId)?.dispose()
  }

  func onSizeChanged(chartId: Int64, width: Double, height: Double) throws {
    chartEngines[chartId]?.onSizeChanged(width: width, height: height)
  }

  func loadCandles(chartId: Int64, data: CandleDataListMessage) throws {
    chartEngines[chartId]?.loadCandles(data: data)
  }

  func appendCandle(chartId: Int64, candle: CandleDataMessage) throws {
    chartEngines[chartId]?.appendCandle(candle: candle)
  }

  func updateLastCandle(chartId: Int64, candle: CandleDataMessage) throws {
    chartEngines[chartId]?.updateLastCandle(candle: candle)
  }

  func setMarkers(chartId: Int64, markers: MarkerListMessage) throws {
    chartEngines[chartId]?.setMarkers(markers: markers)
  }

  func addMarker(chartId: Int64, marker: MarkerMessage) throws {
    chartEngines[chartId]?.addMarker(marker: marker)
  }

  func clearMarkers(chartId: Int64) throws {
    chartEngines[chartId]?.clearMarkers()
  }

  func setChartType(chartId: Int64, chartType: String) throws {
    chartEngines[chartId]?.setChartType(chartType: chartType)
  }

  func setTimeframe(chartId: Int64, timeframe: String) throws {
    chartEngines[chartId]?.setTimeframe(timeframe: timeframe)
  }

  func setTheme(chartId: Int64, theme: ThemeMessage) throws {
    chartEngines[chartId]?.setTheme(theme: theme)
  }

  func setConfig(chartId: Int64, config: ConfigMessage) throws {
    chartEngines[chartId]?.setConfig(config: config)
  }

  func scrollToEnd(chartId: Int64) throws {
    chartEngines[chartId]?.scrollToEnd()
  }

  func onPanUpdate(chartId: Int64, deltaX: Double) throws {
    chartEngines[chartId]?.onPanUpdate(deltaX: deltaX)
  }

  func onPanEnd(chartId: Int64, velocityX: Double) throws {
    chartEngines[chartId]?.onPanEnd(velocityX: velocityX)
  }

  func onScaleUpdate(chartId: Int64, scaleFactor: Double, focalPointX: Double) throws {
    chartEngines[chartId]?.onScaleUpdate(scaleFactor: scaleFactor, focalPointX: focalPointX)
  }

  func onScaleEnd(chartId: Int64) throws {
    chartEngines[chartId]?.onScaleEnd()
  }

  func onCrosshairStart(chartId: Int64, x: Double, y: Double) throws {
    chartEngines[chartId]?.onCrosshairStart(x: x, y: y)
  }

  func onCrosshairMove(chartId: Int64, x: Double, y: Double) throws {
    chartEngines[chartId]?.onCrosshairMove(x: x, y: y)
  }

  func onCrosshairEnd(chartId: Int64) throws {
    chartEngines[chartId]?.onCrosshairEnd()
  }
}
