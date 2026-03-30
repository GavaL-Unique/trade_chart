import CoreGraphics
import CoreVideo
import Flutter
import Foundation

final class TextureRenderer: NSObject, FlutterTexture {
  private let textureRegistry: FlutterTextureRegistry
  private(set) var textureId: Int64 = 0
  private var pixelBuffer: CVPixelBuffer?
  private var width: Int = 1
  private var height: Int = 1
  private var scale: CGFloat = 1.0

  init(textureRegistry: FlutterTextureRegistry) {
    self.textureRegistry = textureRegistry
    super.init()
    textureId = textureRegistry.register(self)
  }

  func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
    guard let pixelBuffer else {
      return nil
    }
    return Unmanaged.passRetained(pixelBuffer)
  }

  func resize(width: Int, height: Int, scale: CGFloat = 1.0) {
    self.scale = max(scale, 1.0)
    self.width = max(Int(CGFloat(width) * self.scale), 1)
    self.height = max(Int(CGFloat(height) * self.scale), 1)
    pixelBuffer = Self.makePixelBuffer(width: self.width, height: self.height)
  }

  func drawSolidColor(argb: Int64) {
    render { context in
      let logicalW = CGFloat(width) / scale
      let logicalH = CGFloat(height) / scale
      context.setFillColor(Self.cgColor(from: argb))
      context.fill(CGRect(x: 0, y: 0, width: logicalW, height: logicalH))
    }
  }

  func render(_ drawBlock: (CGContext) -> Void) {
    guard let pixelBuffer else {
      return
    }
    CVPixelBufferLockBaseAddress(pixelBuffer, [])
    defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }

    guard
      let context = CGContext(
        data: CVPixelBufferGetBaseAddress(pixelBuffer),
        width: CVPixelBufferGetWidth(pixelBuffer),
        height: CVPixelBufferGetHeight(pixelBuffer),
        bitsPerComponent: 8,
        bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue |
          CGBitmapInfo.byteOrder32Little.rawValue
      )
    else {
      return
    }

    context.clear(CGRect(x: 0, y: 0, width: width, height: height))
    context.translateBy(x: 0, y: CGFloat(height))
    context.scaleBy(x: scale, y: -scale)
    drawBlock(context)
    textureRegistry.textureFrameAvailable(textureId)
  }

  func releaseTexture() {
    textureRegistry.unregisterTexture(textureId)
    pixelBuffer = nil
  }

  private static func makePixelBuffer(width: Int, height: Int) -> CVPixelBuffer? {
    let attributes: [CFString: Any] = [
      kCVPixelBufferCGImageCompatibilityKey: true,
      kCVPixelBufferCGBitmapContextCompatibilityKey: true,
      kCVPixelBufferMetalCompatibilityKey: true,
    ]
    var buffer: CVPixelBuffer?
    CVPixelBufferCreate(
      kCFAllocatorDefault,
      width,
      height,
      kCVPixelFormatType_32BGRA,
      attributes as CFDictionary,
      &buffer
    )
    return buffer
  }

  private static func cgColor(from argb: Int64) -> CGColor {
    let alpha = CGFloat((argb >> 24) & 0xFF) / 255.0
    let red = CGFloat((argb >> 16) & 0xFF) / 255.0
    let green = CGFloat((argb >> 8) & 0xFF) / 255.0
    let blue = CGFloat(argb & 0xFF) / 255.0
    return CGColor(red: red, green: green, blue: blue, alpha: alpha)
  }
}
