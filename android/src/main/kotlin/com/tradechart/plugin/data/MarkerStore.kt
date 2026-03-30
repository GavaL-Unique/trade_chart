package com.tradechart.plugin.data

import com.tradechart.plugin.bridge.generated.MarkerMessage

class MarkerStore {
    private val markers = mutableListOf<MarkerMessage>()

    fun set(items: List<MarkerMessage>) {
        markers.clear()
        markers.addAll(items.filter(::isRenderable))
        markers.sortBy { it.timestamp }
    }

    fun add(marker: MarkerMessage) {
        if (!isRenderable(marker)) {
            return
        }
        val insertIndex = markers.binarySearch { existing ->
            existing.timestamp.compareTo(marker.timestamp)
        }.let { index ->
            if (index >= 0) {
                index + 1
            } else {
                -index - 1
            }
        }
        markers.add(insertIndex, marker)
    }

    fun clear() {
        markers.clear()
    }

    fun visibleMarkers(
        startTimestamp: Long,
        endTimestamp: Long,
    ): List<MarkerMessage> {
        if (markers.isEmpty()) {
            return emptyList()
        }
        val startIndex = markers.binarySearch { marker ->
            marker.timestamp.compareTo(startTimestamp)
        }.let { index ->
            if (index >= 0) {
                index
            } else {
                -index - 1
            }
        }

        val visible = ArrayList<MarkerMessage>()
        for (index in startIndex until markers.size) {
            val marker = markers[index]
            if (marker.timestamp > endTimestamp) {
                break
            }
            visible.add(marker)
        }
        return visible
    }

    private fun isRenderable(marker: MarkerMessage): Boolean {
        return marker.id.isNotBlank() &&
            marker.timestamp >= 0 &&
            marker.price.isFinite() &&
            (marker.type == "buy" || marker.type == "sell")
    }
}
