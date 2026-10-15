package com.screencast

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.IBinder
import android.util.DisplayMetrics
import android.util.Log
import androidx.core.app.NotificationCompat
import org.webrtc.EglBase
import org.webrtc.PeerConnectionFactory

class CaptureService : Service() {

    private val TAG = "CaptureService"
    private val NOTIFICATION_ID = 1
    private val CHANNEL_ID = "screen_cast_channel"

    private var rootEglBase: EglBase? = null
    private var peerConnectionManager: PeerConnectionManager? = null
    private var screenCaptureManager: ScreenCaptureManager? = null
    private var signalingClient: SignalingClient? = null

    override fun onCreate() {
        super.onCreate()
        rootEglBase = EglBase.create()
        PeerConnectionFactory.initialize(
            PeerConnectionFactory.InitializationOptions.builder(this)
                .setEnableInternalTracer(true)
                .createInitializationOptions()
        )
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val mediaProjection = intent?.getParcelableExtra<MediaProjection>(MediaProjectionManager.EXTRA_MEDIA_PROJECTION)
        val ipAddress = intent?.getStringExtra("ip_address") ?: "192.168.1.100"
        val port = intent?.getIntExtra("port", 8888) ?: 8888

        if (mediaProjection == null) {
            Log.e(TAG, "No MediaProjection provided")
            stopSelf()
            return START_NOT_STICKY
        }

        startForeground(NOTIFICATION_ID, createNotification())

        val metrics = DisplayMetrics()
        val windowManager = getSystemService(Context.WINDOW_SERVICE) as android.view.WindowManager
        windowManager.defaultDisplay.getRealMetrics(metrics)

        val width = metrics.widthPixels
        val height = metrics.heightPixels
        val dpi = metrics.densityDpi

        signalingClient = SignalingClient(
            serverUrl = "ws://$ipAddress:$port/ws",
            onMessage = { /* handled by peerConnectionManager */ },
            onConnected = { },
            onDisconnected = { error ->
                Log.e(TAG, "Signaling disconnected: $error")
                stopSelf()
            }
        )

        screenCaptureManager = ScreenCaptureManager(this, PeerConnectionFactory.builder().createPeerConnectionFactory(), rootEglBase!!)

        peerConnectionManager = PeerConnectionManager(
            context = this,
            rootEglBase = rootEglBase!!,
            signalingClient = signalingClient!!,
            screenCaptureManager = screenCaptureManager!!,
            onStateChange = { state ->
                Log.d(TAG, "Connection state: $state")
                updateNotification(state)
            },
            onError = { error ->
                Log.e(TAG, "Error: $error")
                stopSelf()
            }
        )

        peerConnectionManager!!.initialize(width, height, dpi)
        signalingClient!!.connect()

        // Request screen capture after signaling connects
        // The actual startCapture will be called after WebSocket connects

        return START_STICKY
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Screen Casting",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Screen casting to iPad"
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("ScreenCast")
            .setContentText("Casting screen to iPad")
            .setSmallIcon(android.R.drawable.ic_media_play)
            .setOngoing(true)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }

    private fun updateNotification(state: org.webrtc.PeerConnection.PeerConnectionState) {
        val text = when (state) {
            org.webrtc.PeerConnection.PeerConnectionState.CONNECTED -> "Connected - Streaming"
            org.webrtc.PeerConnection.PeerConnectionState.CONNECTING -> "Connecting to iPad..."
            else -> "Casting screen to iPad"
        }
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("ScreenCast")
            .setContentText(text)
            .setSmallIcon(android.R.drawable.ic_media_play)
            .setOngoing(true)
            .build()
        val manager = getSystemService(NotificationManager::class.java)
        manager.notify(NOTIFICATION_ID, notification)
    }

    override fun onDestroy() {
        peerConnectionManager?.stop()
        screenCaptureManager?.stopCapture()
        rootEglBase?.release()
        stopForeground(true)
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}