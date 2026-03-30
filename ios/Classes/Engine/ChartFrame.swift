import CoreGraphics
import Foundation

struct CrosshairState {
  let candleIndex: Int
  let snappedX: CGFloat
  let y: CGFloat
}

struct ChartFrame {
  let context: CGContext
  let candleStore: CandleStore
  let markerStore: MarkerStore
  let viewport: ViewportCalculator
  let theme: NativeChartTheme
  let config: ConfigMessage
  let chartType: String
  let width: Int
  let height: Int
  let contentRect: CGRect
  let mainChartRect: CGRect
  let volumeRect: CGRect?
  let priceAxisRect: CGRect?
  let timeAxisRect: CGRect?
  let crosshair: CrosshairState?
}
