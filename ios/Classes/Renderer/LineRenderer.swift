import Foundation

final class LineRenderer: ChartLayerRenderer {
  func render(frame: ChartFrame) {
    guard frame.chartType == "line", frame.viewport.hasVisibleRange() else { return }

    let context = frame.context
    let chartRect = frame.mainChartRect

    context.setStrokeColor(frame.theme.lineColor)
    context.setLineWidth(2)
    context.beginPath()

    for index in frame.viewport.visibleStartIndex...frame.viewport.visibleEndIndex {
      let x = frame.viewport.xCenter(for: index, plotLeft: chartRect.minX)
      let y = frame.viewport.priceToY(
        frame.candleStore.close(at: index),
        top: chartRect.minY,
        height: chartRect.height
      )
      if index == frame.viewport.visibleStartIndex {
        context.move(to: CGPoint(x: x, y: y))
      } else {
        context.addLine(to: CGPoint(x: x, y: y))
      }
    }

    context.strokePath()
  }
}
