package com.screencast

import android.annotation.SuppressLint
import android.content.Context
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaFormat
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.DisplayMetrics
import android.util.Log
import android.view.Surface
import org.webrtc.*
import java.nio.ByteBuffer
import java.util.concurrent.*

class ScreenCapturer(
    private val context: Context,
    private val mediaProjection: MediaProjection,
    private val eglContext: EglBase.Context,
    private val width: Int,
    private val height: Int,
    private val dpi: Int,
    private val fps: Int = 30,
    private val bitrateKbps: Int = 8000
) : VideoCapturer, Runnable {

    private val TAG = "ScreenCapturer"
    private var capturerThread: Thread? = null
    private var isRunning = false
    private var virtualDisplay: android.hardware.display.VirtualDisplay? = null
    private var surface: Surface? = null
    private var mediaCodec: MediaCodec? = null
    private var videoEncoder: VideoEncoder? = null
    private var frameGenerator: FrameGenerator? = null
    private val frameCallback = VideoCapturer.FrameCallback()

    @SuppressLint("WrongThread")
    override fun startCapture(
        width: Int, height: Int, framerate: Int
    ) {
        Log.d(TAG, "startCapture: ${width}x${height}@$framerate")
        this.isRunning = true
        this.capturerThread = Thread(this, "ScreenCapturer").apply { start() }
    }

    override fun stopCapture() {
        Log.d(TAG, "stopCapture")
        isRunning = false
        capturerThread?.interrupt()
        capturerThread?.join(2000)
        cleanup()
    }

    override fun changeCaptureFormat(width: Int, height: Int, framerate: Int) {
        // Not needed for screen capture
    }

    override fun dispose() {
        stopCapture()
    }

    override fun isScreencast(): Boolean = true

    override fun run() {
        setupVirtualDisplay()
        setupEncoder()
        startFrameGenerator()

        // Keep thread alive
        while (isRunning && !Thread.currentThread().isInterrupted) {
            Thread.sleep(100)
        }
    }

    private fun setupVirtualDisplay() {
        val metrics = DisplayMetrics().apply {
            widthPixels = width
            heightPixels = height
            densityDpi = dpi
        }

        surface = mediaProjection.createVirtualDisplay(
            "ScreenCast",
            width, height, dpi,
            android.hardware.display.DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR |
            android.hardware.display.DisplayManager.VIRTUAL_DISPLAY_FLAG_PUBLIC,
            null, null, null
        )?.apply {
            // Note: MediaProjection.createVirtualDisplay with Surface requires API 26+
            // For API 21-25, we'd use MediaProjection.createVirtualDisplay with callback
        }?.surface

        if (surface == null) {
            Log.e(TAG, "Failed to create virtual display")
            stopCapture()
        }
    }

    private fun setupEncoder() {
        try {
            val format = MediaFormat.createVideoFormat(MediaFormat.MIMETYPE_VIDEO_AVC, width, height)
            format.setInteger(MediaFormat.KEY_BIT_RATE, bitrateKbps * 1000)
            format.setInteger(MediaFormat.KEY_FRAME_RATE, fps)
            format.setInteger(MediaFormat.KEY_COLOR_FORMAT, MediaCodecInfo.CodecCapabilities.COLOR_FormatSurface)
            format.setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, 2)
            format.setInteger(MediaFormat.KEY_PROFILE, MediaCodecInfo.CodecProfileLevel.AVCProfileHigh)
            format.setInteger(MediaFormat.KEY_LEVEL, MediaCodecInfo.CodecProfileLevel.AVCLevel41)

            mediaCodec = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_VIDEO_AVC)
            mediaCodec?.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
            surface = mediaCodec?.createInputSurface()
            mediaCodec?.start()

            videoEncoder = VideoEncoder(mediaCodec!!, width, height, fps)
            videoEncoder?.start()
        } catch (e: Exception) {
            Log.e(TAG, "Encoder setup failed", e)
            stopCapture()
        }
    }

    private fun startFrameGenerator() {
        frameGenerator = FrameGenerator(surface!!, eglContext, width, height)
        frameGenerator?.start { buffer ->
            videoEncoder?.encodeFrame(buffer)
        }
    }

    private fun cleanup() {
        frameGenerator?.stop()
        videoEncoder?.stop()
        mediaCodec?.stop()
        mediaCodec?.release()
        virtualDisplay?.release()
        surface?.release()
    }

    inner class FrameGenerator(
        private val inputSurface: Surface,
        private val eglContext: EglBase.Context,
        private val width: Int,
        private val height: Int
    ) {
        private var renderThread: Thread? = null
        private var isRunning = false
        private var eglBase: EglBase? = null
        private var eglSurface: EglBase.Surface? = null
        private var textureBuffer: TextureBufferImpl? = null
        private val frameCallback = VideoCapturer.FrameCallback()

        fun start(onFrame: (VideoFrame) -> Unit) {
            isRunning = true
            eglBase = EglBase.create(eglContext, EglBase.CONFIG_PIXEL_RGBA_BUFFER)
            eglSurface = eglBase!!.createFromSurface(inputSurface)
            textureBuffer = TextureBufferImpl(width, height, EglBase.Context.EGL_NO_CONTEXT)

            renderThread = Thread({
                eglBase!!.makeCurrent(eglSurface!!)
                while (isRunning && !Thread.currentThread().isInterrupted) {
                    // The virtual display automatically feeds frames to the encoder surface
                    // We just need to signal frame availability
                    val timestampNs = System.nanoTime()
                    val frame = VideoFrame.Builder(textureBuffer!!, 0, timestampNs).build()
                    frameCallback.onFrame(frame)
                    onFrame(frame)
                    
                    // Control frame rate
                    Thread.sleep(1000 / fps)
                }
            }, "FrameGenerator").apply { start() }
        }

        fun stop() {
            isRunning = false
            renderThread?.interrupt()
            renderThread?.join(1000)
            eglSurface?.release()
            eglBase?.release()
            textureBuffer?.release()
        }
    }

    inner class VideoEncoder(
        private val codec: MediaCodec,
        private val width: Int,
        private val height: Int,
        private val fps: Int
    ) {
        private var encodeThread: Thread? = null
        private var isRunning = false
        private val outputBufferInfo = MediaCodec.BufferInfo()

        fun start() {
            isRunning = true
            encodeThread = Thread({
                while (isRunning && !Thread.currentThread().isInterrupted) {
                    val index = codec.dequeueOutputBuffer(outputBufferInfo, 10000)
                    if (index >= 0) {
                        val outputBuffer = codec.getOutputBuffer(index)
                        if (outputBuffer != null && outputBufferInfo.size > 0) {
                            // Process encoded frame
                            processEncodedFrame(outputBuffer, outputBufferInfo)
                        }
                        codec.releaseOutputBuffer(index, false)
                    } else if (index == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                        val newFormat = codec.outputFormat
                        Log.d(TAG, "Encoder format changed: $newFormat")
                    }
                }
            }, "VideoEncoder").apply { start() }
        }

        fun encodeFrame(frame: VideoFrame) {
            // Frame is already on the input surface via virtual display
            // MediaCodec pulls from surface automatically
        }

        private fun processEncodedFrame(buffer: ByteBuffer, info: MediaCodec.BufferInfo) {
            // In a full implementation, we'd packetize this into RTP
            // and send via WebRTC's custom video track
            // For now, WebRTC's built-in encoding handles this
        }

        fun stop() {
            isRunning = false
            encodeThread?.interrupt()
            encodeThread?.join(1000)
        }
    }
}