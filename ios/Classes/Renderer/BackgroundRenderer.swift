import Foundation

final class BackgroundRenderer: ChartLayerRenderer {
  func render(frame: ChartFrame) {
    frame.context.setFillColor(frame.theme.backgroundColor)
    frame.context.fill(CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
  }
}
