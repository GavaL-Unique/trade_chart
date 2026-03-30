import Foundation
import UIKit

final class CrosshairRenderer: ChartLayerRenderer {
  func render(frame: ChartFrame) {
    guard let crosshair = frame.crosshair else { return }

    let context = frame.context
    context.saveGState()
    defer { context.restoreGState() }

    context.setStrokeColor(frame.theme.crosshairColor)
    context.setLineWidth(1)
    context.move(to: CGPoint(x: crosshair.snappedX, y: frame.contentRect.minY))
    context.addLine(to: CGPoint(x: crosshair.snappedX, y: frame.contentRect.maxY))
    context.move(to: CGPoint(x: frame.mainChartRect.minX, y: crosshair.y))
    context.addLine(to: CGPoint(x: frame.mainChartRect.maxX, y: crosshair.y))
    context.strokePath()

    UIGraphicsPushContext(context)
    defer { UIGraphicsPopContext() }

    if let priceAxisRect = frame.priceAxisRect {
      let price = priceAtCrosshairY(frame: frame, y: crosshair.y)
      let text = NSString(format: "%.2f", price)
      let textSize = text.size(withAttributes: frame.theme.crosshairAttributes)
      let labelRect = CGRect(
        x: priceAxisRect.minX + 4,
        y: crosshair.y - textSize.height / 2 - 4,
        width: textSize.width + 12,
        height: textSize.height + 8
      )
      let labelPath = UIBezierPath(roundedRect: labelRect, cornerRadius: 6)
      frame.context.setFillColor(frame.theme.crosshairLabelBackgroundColor)
      frame.context.addPath(labelPath.cgPath)
      frame.context.fillPath()
      text.draw(
        at: CGPoint(x: labelRect.minX + 6, y: labelRect.minY + 4),
        withAttributes: frame.theme.crosshairAttributes
      )
    }

    if let timeAxisRect = frame.timeAxisRect {
      let timestamp = frame.candleStore.timestamp(at: crosshair.candleIndex)
      let text = formatTimestamp(timestamp: timestamp, timeframe: frame.candleStore.timeframe)
      let textSize = text.size(withAttributes: frame.theme.crosshairAttributes)
      let labelRect = CGRect(
        x: crosshair.snappedX - (textSize.width / 2) - 6,
        y: timeAxisRect.minY + 2,
        width: textSize.width + 12,
        height: textSize.height + 8
      )
      let clampedRect = labelRect.offsetBy(
        dx: min(max(frame.contentRect.minX - labelRect.minX, 0), frame.contentRect.maxX - labelRect.maxX),
        dy: 0
      )
      let labelPath = UIBezierPath(roundedRect: clampedRect, cornerRadius: 6)
      frame.context.setFillColor(frame.theme.crosshairLabelBackgroundColor)
      frame.context.addPath(labelPath.cgPath)
      frame.context.fillPath()
      text.draw(
        at: CGPoint(x: clampedRect.minX + 6, y: clampedRect.minY + 4),
        withAttributes: frame.theme.crosshairAttributes
      )
    }
  }

  private func priceAtCrosshairY(frame: ChartFrame, y: CGFloat) -> Double {
    let ratio = min(max((y - frame.mainChartRect.minY) / frame.mainChartRect.height, 0), 1)
    return frame.viewport.priceHigh - (frame.viewport.priceHigh - frame.viewport.priceLow) * Double(ratio)
  }

  private func formatTimestamp(timestamp: Int64, timeframe: String) -> NSString {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    switch timeframe {
    case "d1", "w1", "M1":
      formatter.dateFormat = "MM-dd"
    default:
      formatter.dateFormat = "HH:mm"
    }
    let date = Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000.0)
    return formatter.string(from: date) as NSString
  }
}
