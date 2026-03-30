package com.tradechart.plugin.theme

import android.graphics.Color
import android.graphics.Paint
import android.text.TextPaint
import com.tradechart.plugin.bridge.generated.ThemeMessage

class NativeChartTheme(
    message: ThemeMessage,
) {
    val backgroundColorArgb: Long = message.backgroundColorArgb

    val backgroundPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = message.backgroundColorArgb.toInt()
        style = Paint.Style.FILL
    }
    val gridPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = message.gridColorArgb.toInt()
        style = Paint.Style.STROKE
        strokeWidth = 1f
    }
    val bullPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = message.bullColorArgb.toInt()
        style = Paint.Style.FILL
    }
    val bearPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = message.bearColorArgb.toInt()
        style = Paint.Style.FILL
    }
    val bullWickPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = message.bullColorArgb.toInt()
        style = Paint.Style.STROKE
        strokeWidth = 2f
    }
    val bearWickPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = message.bearColorArgb.toInt()
        style = Paint.Style.STROKE
        strokeWidth = 2f
    }
    val volumeBullPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = message.volumeBullColorArgb.toInt()
        style = Paint.Style.FILL
    }
    val volumeBearPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = message.volumeBearColorArgb.toInt()
        style = Paint.Style.FILL
    }
    val linePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = message.bullColorArgb.toInt()
        style = Paint.Style.STROKE
        strokeWidth = 2f
    }
    val buyMarkerPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = message.buyMarkerColorArgb.toInt()
        style = Paint.Style.FILL
    }
    val sellMarkerPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = message.sellMarkerColorArgb.toInt()
        style = Paint.Style.FILL
    }
    val axisPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = message.axisColorArgb.toInt()
        style = Paint.Style.STROKE
        strokeWidth = 1f
    }
    val axisTextPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
        color = message.textColorArgb.toInt()
        textSize = message.axisTextSize.toFloat()
    }
    val crosshairPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = message.crosshairColorArgb.toInt()
        style = Paint.Style.STROKE
        strokeWidth = 1f
    }
    val crosshairLabelBackgroundPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = message.crosshairLabelBgColorArgb.toInt()
        style = Paint.Style.FILL
    }
    val crosshairTextPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
        color = message.textColorArgb.toInt()
        textSize = message.crosshairTextSize.toFloat()
    }
    val markerTextPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
        color = message.textColorArgb.toInt()
        textSize = message.crosshairTextSize.toFloat()
    }
}
