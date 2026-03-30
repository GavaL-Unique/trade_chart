import Foundation

final class ChartFlutterApiHolder {
  init(flutterApi: ChartFlutterApi) {
    self.flutterApi = flutterApi
  }

  private let flutterApi: ChartFlutterApi

  func onChartReady() {
    flutterApi.onChartReady { _ in }
  }

  func onViewportChanged(_ viewport: ViewportStateMessage) {
    flutterApi.onViewportChanged(viewport: viewport) { _ in }
  }

  func onCrosshairData(_ data: CrosshairDataMessage) {
    flutterApi.onCrosshairData(data: data) { _ in }
  }

  func onError(code: String, message: String) {
    flutterApi.onError(code: code, message: message) { _ in }
  }
}
