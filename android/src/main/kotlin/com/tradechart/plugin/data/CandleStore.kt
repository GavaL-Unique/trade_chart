package com.tradechart.plugin.data

import com.tradechart.plugin.bridge.generated.CandleDataListMessage
import com.tradechart.plugin.bridge.generated.CandleDataMessage

class CandleStore {
    private var timestamps = LongArray(0)
    private var opens = DoubleArray(0)
    private var highs = DoubleArray(0)
    private var lows = DoubleArray(0)
    private var closes = DoubleArray(0)
    private var volumes = DoubleArray(0)

    var timeframe: String = "m1"
        private set

    var count: Int = 0
        private set

    companion object {
        private const val ANIM_DURATION = 0.15
    }

    private var animFromOpen = 0.0
    private var animFromHigh = 0.0
    private var animFromLow = 0.0
    private var animFromClose = 0.0
    private var animFromVolume = 0.0
    private var animProgress = 1.0
    var isAnimating: Boolean = false
        private set

    fun load(data: CandleDataListMessage) {
        val size = data.candles.size
        timestamps = LongArray(size)
        opens = DoubleArray(size)
        highs = DoubleArray(size)
        lows = DoubleArray(size)
        closes = DoubleArray(size)
        volumes = DoubleArray(size)
        timeframe = data.timeframe
        count = size

        data.candles.forEachIndexed { index, candle ->
            write(index, candle)
        }
        resetAnimation()
    }

    fun append(candle: CandleDataMessage) {
        resetAnimation()
        ensureCapacity(count + 1)
        write(count, candle)
        count += 1
    }

    fun updateLast(candle: CandleDataMessage) {
        if (count == 0) {
            append(candle)
            return
        }
        val last = count - 1
        animFromOpen = openAt(last)
        animFromHigh = highAt(last)
        animFromLow = lowAt(last)
        animFromClose = closeAt(last)
        animFromVolume = volumeAt(last)

        write(last, candle)

        animProgress = 0.0
        isAnimating = true
    }

    fun advanceAnimation(dt: Double) {
        if (!isAnimating) return
        animProgress += dt / ANIM_DURATION
        if (animProgress >= 1.0) {
            animProgress = 1.0
            isAnimating = false
        }
    }

    fun clear() {
        timestamps = LongArray(0)
        opens = DoubleArray(0)
        highs = DoubleArray(0)
        lows = DoubleArray(0)
        closes = DoubleArray(0)
        volumes = DoubleArray(0)
        count = 0
        resetAnimation()
    }

    fun timestampAt(index: Int): Long = timestamps[index]

    fun openAt(index: Int): Double {
        if (isAnimating && index == count - 1) return lerp(animFromOpen, opens[index], animProgress)
        return opens[index]
    }

    fun highAt(index: Int): Double {
        if (isAnimating && index == count - 1) return lerp(animFromHigh, highs[index], animProgress)
        return highs[index]
    }

    fun lowAt(index: Int): Double {
        if (isAnimating && index == count - 1) return lerp(animFromLow, lows[index], animProgress)
        return lows[index]
    }

    fun closeAt(index: Int): Double {
        if (isAnimating && index == count - 1) return lerp(animFromClose, closes[index], animProgress)
        return closes[index]
    }

    fun volumeAt(index: Int): Double {
        if (isAnimating && index == count - 1) return lerp(animFromVolume, volumes[index], animProgress)
        return volumes[index]
    }

    fun lastTimestampOrNull(): Long? = if (count == 0) null else timestamps[count - 1]

    private fun lerp(from: Double, to: Double, t: Double): Double = from + (to - from) * t

    private fun resetAnimation() {
        isAnimating = false
        animProgress = 1.0
    }

    fun indexOfTimestamp(timestamp: Long): Int {
        var low = 0
        var high = count - 1
        while (low <= high) {
            val mid = (low + high).ushr(1)
            val value = timestamps[mid]
            when {
                value < timestamp -> low = mid + 1
                value > timestamp -> high = mid - 1
                else -> return mid
            }
        }
        return -1
    }

    private fun ensureCapacity(requiredSize: Int) {
        if (requiredSize <= timestamps.size) {
            return
        }
        val newSize = requiredSize.coerceAtLeast((timestamps.size.coerceAtLeast(1)) * 2)
        timestamps = timestamps.copyOf(newSize)
        opens = opens.copyOf(newSize)
        highs = highs.copyOf(newSize)
        lows = lows.copyOf(newSize)
        closes = closes.copyOf(newSize)
        volumes = volumes.copyOf(newSize)
    }

    private fun write(index: Int, candle: CandleDataMessage) {
        timestamps[index] = candle.timestamp
        opens[index] = candle.open
        highs[index] = candle.high
        lows[index] = candle.low
        closes[index] = candle.close
        volumes[index] = candle.volume
    }
}
