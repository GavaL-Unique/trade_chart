import Foundation

final class GridRenderer: ChartLayerRenderer {
  func render(frame: ChartFrame) {
    guard frame.config.showGrid else { return }

    let context = frame.context
    context.setStrokeColor(frame.theme.gridColor)
    context.setLineWidth(1)

    let main = frame.mainChartRect
    let horizontalLines = 4
    for step in 0...horizontalLines {
      let y = main.minY + main.height / CGFloat(horizontalLines) * CGFloat(step)
      context.move(to: CGPoint(x: main.minX, y: y))
      context.addLine(to: CGPoint(x: main.maxX, y: y))
    }

    if let volume = frame.volumeRect {
      context.move(to: CGPoint(x: volume.minX, y: volume.minY))
      context.addLine(to: CGPoint(x: volume.maxX, y: volume.minY))
      context.move(to: CGPoint(x: volume.minX, y: volume.maxY))
      context.addLine(to: CGPoint(x: volume.maxX, y: volume.maxY))
    }

    let verticalLines = 4
    for step in 0...verticalLines {
      let x = main.minX + main.width / CGFloat(verticalLines) * CGFloat(step)
      context.move(to: CGPoint(x: x, y: main.minY))
      context.addLine(to: CGPoint(x: x, y: main.maxY))
      if let volume = frame.volumeRect {
        context.move(to: CGPoint(x: x, y: volume.minY))
        context.addLine(to: CGPoint(x: x, y: volume.maxY))
      }
    }

    context.strokePath()
  }
}
