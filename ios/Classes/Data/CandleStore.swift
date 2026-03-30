import Foundation

final class CandleStore {
  private var timestamps: [Int64] = []
  private var opens: [Double] = []
  private var highs: [Double] = []
  private var lows: [Double] = []
  private var closes: [Double] = []
  private var volumes: [Double] = []

  private(set) var timeframe: String = "m1"

  // Last-candle animation state
  private static let animDuration: Double = 0.15
  private var animFromOpen: Double = 0
  private var animFromHigh: Double = 0
  private var animFromLow: Double = 0
  private var animFromClose: Double = 0
  private var animFromVolume: Double = 0
  private var animProgress: Double = 1.0
  private(set) var isAnimating: Bool = false

  var count: Int {
    timestamps.count
  }

  func load(data: CandleDataListMessage) {
    let candles = data.candles
    timeframe = data.timeframe
    timestamps = candles.map(\.timestamp)
    opens = candles.map(\.open)
    highs = candles.map(\.high)
    lows = candles.map(\.low)
    closes = candles.map(\.close)
    volumes = candles.map(\.volume)
    resetAnimation()
  }

  func append(candle: CandleDataMessage) {
    resetAnimation()
    timestamps.append(candle.timestamp)
    opens.append(candle.open)
    highs.append(candle.high)
    lows.append(candle.low)
    closes.append(candle.close)
    volumes.append(candle.volume)
  }

  func updateLast(candle: CandleDataMessage) {
    if timestamps.isEmpty {
      append(candle: candle)
      return
    }

    let last = count - 1
    animFromOpen = open(at: last)
    animFromHigh = high(at: last)
    animFromLow = low(at: last)
    animFromClose = close(at: last)
    animFromVolume = volume(at: last)

    timestamps[last] = candle.timestamp
    opens[last] = candle.open
    highs[last] = candle.high
    lows[last] = candle.low
    closes[last] = candle.close
    volumes[last] = candle.volume

    animProgress = 0
    isAnimating = true
  }

  func advanceAnimation(dt: Double) {
    guard isAnimating else { return }
    animProgress += dt / CandleStore.animDuration
    if animProgress >= 1.0 {
      animProgress = 1.0
      isAnimating = false
    }
  }

  func clear() {
    timestamps.removeAll(keepingCapacity: false)
    opens.removeAll(keepingCapacity: false)
    highs.removeAll(keepingCapacity: false)
    lows.removeAll(keepingCapacity: false)
    closes.removeAll(keepingCapacity: false)
    volumes.removeAll(keepingCapacity: false)
    resetAnimation()
  }

  func timestamp(at index: Int) -> Int64 { timestamps[index] }

  func open(at index: Int) -> Double {
    if isAnimating && index == count - 1 {
      return lerp(animFromOpen, opens[index], animProgress)
    }
    return opens[index]
  }

  func high(at index: Int) -> Double {
    if isAnimating && index == count - 1 {
      return lerp(animFromHigh, highs[index], animProgress)
    }
    return highs[index]
  }

  func low(at index: Int) -> Double {
    if isAnimating && index == count - 1 {
      return lerp(animFromLow, lows[index], animProgress)
    }
    return lows[index]
  }

  func close(at index: Int) -> Double {
    if isAnimating && index == count - 1 {
      return lerp(animFromClose, closes[index], animProgress)
    }
    return closes[index]
  }

  func volume(at index: Int) -> Double {
    if isAnimating && index == count - 1 {
      return lerp(animFromVolume, volumes[index], animProgress)
    }
    return volumes[index]
  }

  func lastTimestampOrNil() -> Int64? { timestamps.last }

  private func lerp(_ from: Double, _ to: Double, _ t: Double) -> Double {
    from + (to - from) * t
  }

  private func resetAnimation() {
    isAnimating = false
    animProgress = 1.0
  }

  func indexOfTimestamp(_ timestamp: Int64) -> Int {
    var low = 0
    var high = timestamps.count - 1
    while low <= high {
      let mid = (low + high) / 2
      let value = timestamps[mid]
      if value < timestamp {
        low = mid + 1
      } else if value > timestamp {
        high = mid - 1
      } else {
        return mid
      }
    }
    return -1
  }
}
