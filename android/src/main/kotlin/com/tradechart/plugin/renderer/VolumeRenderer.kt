package com.tradechart.plugin.renderer

import android.graphics.RectF
import com.tradechart.plugin.engine.ChartFrame
import kotlin.math.max

class VolumeRenderer : ChartLayerRenderer {
    override fun render(frame: ChartFrame) {
        val volumeRect = frame.volumeRect ?: return
        if (!frame.config.showVolume || !frame.viewport.hasVisibleRange()) {
            return
        }

        val bodyWidth = max(1f, frame.viewport.candleBodyWidth() * 0.7f)
        for (index in frame.viewport.visibleStartIndex..frame.viewport.visibleEndIndex) {
            val centerX = frame.viewport.xCenterForIndex(index, frame.mainChartRect.left)
            val volumeTop = frame.viewport.volumeToY(
                frame.candleStore.volumeAt(index),
                volumeRect.top,
                volumeRect.height(),
            )
            val rect = RectF(
                centerX - bodyWidth / 2f,
                volumeTop,
                centerX + bodyWidth / 2f,
                volumeRect.bottom,
            )
            val paint = if (frame.candleStore.closeAt(index) >= frame.candleStore.openAt(index)) {
                frame.theme.volumeBullPaint
            } else {
                frame.theme.volumeBearPaint
            }
            frame.canvas.drawRect(rect, paint)
        }
    }
}
