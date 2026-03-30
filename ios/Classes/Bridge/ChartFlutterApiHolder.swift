import Foundation

final class ChartFlutterApiHolder {
  init(flutterApi: ChartFlutterApi) {
    self.flutterApi = flutterApi
  }

  private let flutterApi: ChartFlutterApi

  func onChartReady(chartId: Int64) {
    flutterApi.onChartReady(chartId: chartId) { _ in }
  }

  func onViewportChanged(chartId: Int64, viewport: ViewportStateMessage) {
    flutterApi.onViewportChanged(chartId: chartId, viewport: viewport) { _ in }
  }

  func onCrosshairData(chartId: Int64, data: CrosshairDataMessage) {
    flutterApi.onCrosshairData(chartId: chartId, data: data) { _ in }
  }

  func onError(chartId: Int64, code: String, message: String) {
    flutterApi.onError(chartId: chartId, code: code, message: message) { _ in }
  }
}
