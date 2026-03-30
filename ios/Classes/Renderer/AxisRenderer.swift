import Foundation
import UIKit

final class AxisRenderer: ChartLayerRenderer {
  func render(frame: ChartFrame) {
    guard frame.config.showAxis, let priceAxisRect = frame.priceAxisRect, let timeAxisRect = frame.timeAxisRect else {
      return
    }

    let context = frame.context
    context.setStrokeColor(frame.theme.axisColor)
    context.setLineWidth(1)
    context.move(to: CGPoint(x: frame.mainChartRect.maxX, y: frame.mainChartRect.minY))
    context.addLine(to: CGPoint(x: frame.mainChartRect.maxX, y: frame.mainChartRect.maxY))
    context.move(to: CGPoint(x: frame.mainChartRect.minX, y: frame.mainChartRect.maxY))
    context.addLine(to: CGPoint(x: frame.mainChartRect.maxX, y: frame.mainChartRect.maxY))
    context.strokePath()

    guard frame.viewport.hasVisibleRange() else { return }

    UIGraphicsPushContext(context)
    defer { UIGraphicsPopContext() }

    let labelCount = 4
    for step in 0...labelCount {
      let ratio = CGFloat(step) / CGFloat(labelCount)
      let price = frame.viewport.priceHigh - (frame.viewport.priceHigh - frame.viewport.priceLow) * Double(ratio)
      let y = frame.mainChartRect.minY + frame.mainChartRect.height * ratio
      let text = formatPrice(price)
      text.draw(
        at: CGPoint(x: priceAxisRect.minX + 6, y: y - frame.theme.axisFont.lineHeight / 2),
        withAttributes: frame.theme.axisAttributes
      )
    }

    // Bybit-style: ticks spaced along visible candle indices; x uses fractional index so labels
    // slide with pan (integer-only xCenter + floor(visibleStart) made text update while x felt stuck).
    let start = frame.viewport.visibleStartIndex
    let end = frame.viewport.visibleEndIndex
    let span = end - start
    let maxSlots = 5
    let slots = min(maxSlots, max(span + 1, 1))
    let denom = max(slots - 1, 1)
    let plotLeft = frame.mainChartRect.minX
    let vs = frame.viewport.scrollOffset
    let sw = frame.viewport.slotWidth
    let count = frame.candleStore.count
    for step in 0..<slots {
      let t = Double(step) / Double(denom)
      let rawIndex = Double(start) + Double(span) * t
      let idx = min(max(Int(rawIndex.rounded()), 0), count - 1)
      let x = plotLeft + CGFloat((rawIndex - vs + 0.5) * sw)
      let timestamp = frame.candleStore.timestamp(at: idx)
      let text = formatTimestamp(timestamp: timestamp, timeframe: frame.candleStore.timeframe)
      let textSize = text.size(withAttributes: frame.theme.axisAttributes)
      let drawX = x - textSize.width / 2
      text.draw(
        at: CGPoint(x: drawX, y: timeAxisRect.minY + 2),
        withAttributes: frame.theme.axisAttributes
      )
    }
  }

  private func formatPrice(_ price: Double) -> NSString {
    NSString(format: "%.2f", price)
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
