import Foundation
import UIKit

final class MarkerRenderer: ChartLayerRenderer {
  func render(frame: ChartFrame) {
    guard frame.viewport.hasVisibleRange() else { return }

    let visibleMarkers = frame.markerStore.visibleMarkers(
      startTimestamp: frame.candleStore.timestamp(at: frame.viewport.visibleStartIndex),
      endTimestamp: frame.candleStore.timestamp(at: frame.viewport.visibleEndIndex)
    )
    guard !visibleMarkers.isEmpty else { return }

    let context = frame.context
    UIGraphicsPushContext(context)
    defer { UIGraphicsPopContext() }

    for marker in visibleMarkers {
      let candleIndex = frame.candleStore.indexOfTimestamp(marker.timestamp)
      guard candleIndex >= frame.viewport.visibleStartIndex, candleIndex <= frame.viewport.visibleEndIndex else {
        continue
      }

      let x = frame.viewport.xCenter(for: candleIndex, plotLeft: frame.mainChartRect.minX)
      let y = frame.viewport.priceToY(
        marker.price,
        top: frame.mainChartRect.minY,
        height: frame.mainChartRect.height
      )
      guard y >= frame.mainChartRect.minY - 24, y <= frame.mainChartRect.maxY + 24 else {
        continue
      }

      let isBuy = marker.type == "buy"
      let path = UIBezierPath()
      if isBuy {
        path.move(to: CGPoint(x: x, y: y - 10))
        path.addLine(to: CGPoint(x: x - 8, y: y + 4))
        path.addLine(to: CGPoint(x: x + 8, y: y + 4))
      } else {
        path.move(to: CGPoint(x: x, y: y + 10))
        path.addLine(to: CGPoint(x: x - 8, y: y - 4))
        path.addLine(to: CGPoint(x: x + 8, y: y - 4))
      }
      path.close()
      context.setFillColor(isBuy ? frame.theme.buyMarkerColor : frame.theme.sellMarkerColor)
      context.addPath(path.cgPath)
      context.fillPath()

      if let label = marker.label, !label.isEmpty {
        let text = label as NSString
        let textSize = text.size(withAttributes: frame.theme.markerAttributes)
        let labelTop = isBuy ? y + 8 : y - textSize.height - 16
        let labelRect = CGRect(
          x: x - textSize.width / 2 - 6,
          y: labelTop,
          width: textSize.width + 12,
          height: textSize.height + 8
        )
        let path = UIBezierPath(roundedRect: labelRect, cornerRadius: 6)
        context.setFillColor(frame.theme.crosshairLabelBackgroundColor)
        context.addPath(path.cgPath)
        context.fillPath()
        text.draw(
          at: CGPoint(x: labelRect.minX + 6, y: labelRect.minY + 4),
          withAttributes: frame.theme.markerAttributes
        )
      }
    }
  }
}
