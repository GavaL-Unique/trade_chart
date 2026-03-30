import Foundation

final class CandleRenderer: ChartLayerRenderer {
  func render(frame: ChartFrame) {
    guard frame.chartType == "candle", frame.viewport.hasVisibleRange() else { return }

    let context = frame.context
    let chartRect = frame.mainChartRect
    let bodyWidth = max(1, frame.viewport.candleBodyWidth())

    for index in frame.viewport.visibleStartIndex...frame.viewport.visibleEndIndex {
      let open = frame.candleStore.open(at: index)
      let close = frame.candleStore.close(at: index)
      let high = frame.candleStore.high(at: index)
      let low = frame.candleStore.low(at: index)

      let centerX = frame.viewport.xCenter(for: index, plotLeft: chartRect.minX)
      let openY = frame.viewport.priceToY(open, top: chartRect.minY, height: chartRect.height)
      let closeY = frame.viewport.priceToY(close, top: chartRect.minY, height: chartRect.height)
      let highY = frame.viewport.priceToY(high, top: chartRect.minY, height: chartRect.height)
      let lowY = frame.viewport.priceToY(low, top: chartRect.minY, height: chartRect.height)

      let isBull = close >= open
      let color = isBull ? frame.theme.bullColor : frame.theme.bearColor

      context.setStrokeColor(color)
      context.setLineWidth(2)
      context.move(to: CGPoint(x: centerX, y: highY))
      context.addLine(to: CGPoint(x: centerX, y: lowY))
      context.strokePath()

      let top = min(openY, closeY)
      let bottom = max(openY, closeY)
      let adjustedBottom = abs(bottom - top) < 1 ? top + 1 : bottom
      let rect = CGRect(
        x: centerX - bodyWidth / 2,
        y: top,
        width: bodyWidth,
        height: adjustedBottom - top
      )
      context.setFillColor(color)
      context.fill(rect)
    }
  }
}
