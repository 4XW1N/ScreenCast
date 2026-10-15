package com.screencast

import android.annotation.SuppressLint
import android.content.Context
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.util.Log
import org.webrtc.*

class ScreenCaptureManager(
    private val context: Context,
    private val peerConnectionFactory: PeerConnectionFactory,
    private val rootEglBase: EglBase
) {

    private val TAG = "ScreenCaptureManager"
    private var mediaProjection: MediaProjection? = null
    private var videoSource: VideoSource? = null
    private var videoTrack: VideoTrack? = null
    private var capturer: ScreenCapturerAndroid? = null

    @SuppressLint("WrongThread")
    fun startCapture(
        mediaProjection: MediaProjection,
        width: Int,
        height: Int,
        fps: Int = 30
    ): VideoTrack {
        this.mediaProjection = mediaProjection

        // Create WebRTC screen capturer
        capturer = ScreenCapturerAndroid(
            mediaProjection,
            object : ScreenCapturerAndroid.ScreenCaptureListener {
                override fun onScreenCaptureStarted() {
                    Log.d(TAG, "Screen capture started")
                }

                override fun onScreenCaptureStopped() {
                    Log.d(TAG, "Screen capture stopped")
                    stopCapture()
                }

                override fun onScreenCaptureError(error: String) {
                    Log.e(TAG, "Screen capture error: $error")
                }
            }
        )

        // Create video source with capturer
        videoSource = peerConnectionFactory.createVideoSource(true)
        videoSource.adaptOutputFormat(width, height, fps)

        // Start capturer
        capturer?.startCapture(width, height, fps)
        capturer?.initialize(
            rootEglBase.context,
            videoSource.getCapturerObserver()!!
        )

        // Create video track
        videoTrack = peerConnectionFactory.createVideoTrack("screenTrack", videoSource!!)
        videoTrack!!.isEnabled = true

        return videoTrack!!
    }

    fun stopCapture() {
        capturer?.stopCapture()
        capturer?.dispose()
        capturer = null

        videoTrack?.dispose()
        videoTrack = null

        videoSource?.dispose()
        videoSource = null

        mediaProjection?.stop()
        mediaProjection = null
    }

    fun getVideoTrack(): VideoTrack? = videoTrack
    fun isCapturing(): Boolean = capturer != null
}