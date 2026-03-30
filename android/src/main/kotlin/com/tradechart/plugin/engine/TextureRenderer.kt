package com.tradechart.plugin.engine

import android.graphics.Canvas
import android.graphics.Color
import android.graphics.PorterDuff
import android.view.Surface
import io.flutter.view.TextureRegistry

class TextureRenderer(
    textureRegistry: TextureRegistry,
) {
    private val textureEntry = textureRegistry.createSurfaceTexture()
    private val surface = Surface(textureEntry.surfaceTexture())
    private var width: Int = 1
    private var height: Int = 1
    private var scale: Float = 1f

    val textureId: Long
        get() = textureEntry.id()

    fun resize(width: Int, height: Int, scale: Float = 1f) {
        this.scale = scale.coerceAtLeast(1f)
        this.width = ((width * this.scale).toInt()).coerceAtLeast(1)
        this.height = ((height * this.scale).toInt()).coerceAtLeast(1)
        textureEntry.surfaceTexture().setDefaultBufferSize(this.width, this.height)
    }

    fun drawSolidColor(argb: Long) {
        render { canvas ->
            canvas.drawColor(Color.TRANSPARENT, PorterDuff.Mode.CLEAR)
            canvas.drawColor(argb.toInt())
        }
    }

    fun render(drawBlock: (Canvas) -> Unit) {
        val canvas = surface.lockCanvas(null)
        try {
            canvas.save()
            canvas.scale(scale, scale)
            drawBlock(canvas)
            canvas.restore()
        } finally {
            surface.unlockCanvasAndPost(canvas)
        }
    }

    fun release() {
        surface.release()
        textureEntry.release()
    }
}
