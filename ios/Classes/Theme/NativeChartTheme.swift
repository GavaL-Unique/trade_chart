import CoreGraphics
import Foundation
import UIKit

struct NativeChartTheme {
  let message: ThemeMessage

  var backgroundColorArgb: Int64 {
    message.backgroundColorArgb
  }

  let backgroundColor: CGColor
  let gridColor: CGColor
  let bullColor: CGColor
  let bearColor: CGColor
  let volumeBullColor: CGColor
  let volumeBearColor: CGColor
  let axisColor: CGColor
  let textColor: UIColor
  let lineColor: CGColor
  let buyMarkerColor: CGColor
  let sellMarkerColor: CGColor
  let crosshairColor: CGColor
  let crosshairLabelBackgroundColor: CGColor
  let axisFont: UIFont
  let crosshairFont: UIFont
  let axisAttributes: [NSAttributedString.Key: Any]
  let crosshairAttributes: [NSAttributedString.Key: Any]
  let markerAttributes: [NSAttributedString.Key: Any]

  init(message: ThemeMessage) {
    self.message = message
    backgroundColor = Self.cgColor(from: message.backgroundColorArgb)
    gridColor = Self.cgColor(from: message.gridColorArgb)
    bullColor = Self.cgColor(from: message.bullColorArgb)
    bearColor = Self.cgColor(from: message.bearColorArgb)
    volumeBullColor = Self.cgColor(from: message.volumeBullColorArgb)
    volumeBearColor = Self.cgColor(from: message.volumeBearColorArgb)
    axisColor = Self.cgColor(from: message.axisColorArgb)
    textColor = Self.uiColor(from: message.textColorArgb)
    lineColor = Self.cgColor(from: message.bullColorArgb)
    buyMarkerColor = Self.cgColor(from: message.buyMarkerColorArgb)
    sellMarkerColor = Self.cgColor(from: message.sellMarkerColorArgb)
    crosshairColor = Self.cgColor(from: message.crosshairColorArgb)
    crosshairLabelBackgroundColor = Self.cgColor(from: message.crosshairLabelBgColorArgb)
    axisFont = .systemFont(ofSize: message.axisTextSize)
    crosshairFont = .systemFont(ofSize: message.crosshairTextSize)
    axisAttributes = [
      .font: axisFont,
      .foregroundColor: textColor,
    ]
    crosshairAttributes = [
      .font: crosshairFont,
      .foregroundColor: textColor,
    ]
    markerAttributes = [
      .font: crosshairFont,
      .foregroundColor: textColor,
    ]
  }

  private static func cgColor(from argb: Int64) -> CGColor {
    let alpha = CGFloat((argb >> 24) & 0xFF) / 255.0
    let red = CGFloat((argb >> 16) & 0xFF) / 255.0
    let green = CGFloat((argb >> 8) & 0xFF) / 255.0
    let blue = CGFloat(argb & 0xFF) / 255.0
    return CGColor(red: red, green: green, blue: blue, alpha: alpha)
  }

  private static func uiColor(from argb: Int64) -> UIColor {
    UIColor(cgColor: cgColor(from: argb))
  }
}
