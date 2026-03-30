import Foundation

final class MarkerStore {
  private var markers: [MarkerMessage] = []

  func set(markers: [MarkerMessage]) {
    self.markers = markers
      .filter(isRenderable)
      .sorted { $0.timestamp < $1.timestamp }
  }

  func add(marker: MarkerMessage) {
    guard isRenderable(marker) else {
      return
    }
    let insertIndex = lowerBound(for: marker.timestamp)
    markers.insert(marker, at: insertIndex)
  }

  func clear() {
    markers.removeAll()
  }

  func visibleMarkers(startTimestamp: Int64, endTimestamp: Int64) -> [MarkerMessage] {
    guard !markers.isEmpty else {
      return []
    }
    let startIndex = lowerBound(for: startTimestamp)
    var visible: [MarkerMessage] = []
    var index = startIndex
    while index < markers.count {
      let marker = markers[index]
      if marker.timestamp > endTimestamp {
        break
      }
      visible.append(marker)
      index += 1
    }
    return visible
  }

  private func lowerBound(for timestamp: Int64) -> Int {
    var low = 0
    var high = markers.count
    while low < high {
      let mid = (low + high) / 2
      if markers[mid].timestamp < timestamp {
        low = mid + 1
      } else {
        high = mid
      }
    }
    return low
  }

  private func isRenderable(_ marker: MarkerMessage) -> Bool {
    !marker.id.isEmpty &&
      marker.timestamp >= 0 &&
      marker.price.isFinite &&
      (marker.type == "buy" || marker.type == "sell")
  }
}
