import Foundation

final class VolumeRenderer: ChartLayerRenderer {
  func render(frame: ChartFrame) {
    guard frame.config.showVolume, frame.viewport.hasVisibleRange(), let volumeRect = frame.volumeRect else {
      return
    }

    let context = frame.context
    let bodyWidth = max(1, frame.viewport.candleBodyWidth() * 0.7)

    for index in frame.viewport.visibleStartIndex...frame.viewport.visibleEndIndex {
      let centerX = frame.viewport.xCenter(for: index, plotLeft: frame.mainChartRect.minX)
      let volumeTop = frame.viewport.volumeToY(
        frame.candleStore.volume(at: index),
        top: volumeRect.minY,
        height: volumeRect.height
      )
      let rect = CGRect(
        x: centerX - bodyWidth / 2,
        y: volumeTop,
        width: bodyWidth,
        height: volumeRect.maxY - volumeTop
      )
      let isBull = frame.candleStore.close(at: index) >= frame.candleStore.open(at: index)
      context.setFillColor(isBull ? frame.theme.volumeBullColor : frame.theme.volumeBearColor)
      context.fill(rect)
    }
  }
}
