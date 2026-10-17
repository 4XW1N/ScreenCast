package com.screencast

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.ImageFormat
import android.graphics.Rect
import android.graphics.YuvImage
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.Image
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Handler
import android.os.HandlerThread
import android.os.IBinder
import android.util.DisplayMetrics
import android.view.Surface
import android.view.WindowManager
import java.io.ByteArrayOutputStream
import java.io.DataOutputStream
import java.net.ServerSocket
import java.net.Socket

class ScreenCastService : Service() {

    private var mediaProjectionManager: MediaProjectionManager? = null
    private var mediaProjection: MediaProjection? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var imageReader: ImageReader? = null
    private var serverThread: Thread? = null
    private var serverSocket: ServerSocket? = null
    private var isRunning = false
    private var handlerThread: HandlerThread? = null
    private var handler: android.os.Handler? = null

    private val PORT = 8080
    private val NOTIFICATION_ID = 1
    private val CHANNEL_ID = "screen_cast_channel"

    override fun onStartCommand(intent: Intent, flags: Int, startId: Int): Int {
        // Start foreground IMMEDIATELY to prevent crash
        startForeground(NOTIFICATION_ID, createNotification("ScreenCast - Starting..."))

        try {
            val resultCode = intent.getIntExtra("mediaProjectionResultCode", -1)
            val data = intent.getParcelableExtra<Intent>("mediaProjectionData")

            if (resultCode == -1 || data == null || isRunning) {
                return START_STICKY
            }

            mediaProjectionManager = getSystemService(MediaProjectionManager::class.java)
            mediaProjection = mediaProjectionManager?.getMediaProjection(resultCode, data)

            if (mediaProjection == null) {
                return START_STICKY
            }

            startCapture()
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent): IBinder? = null

    override fun onDestroy() {
        stopCapture()
        super.onDestroy()
    }

    private fun startCapture() {
        try {
            val metrics = DisplayMetrics()
            val windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
            windowManager.defaultDisplay.getRealMetrics(metrics)

            val width = metrics.widthPixels
            val height = metrics.heightPixels
            val dpi = metrics.densityDpi

            handlerThread = HandlerThread("ScreenCastHandler")
            handlerThread?.start()
            handler = android.os.Handler(handlerThread!!.looper)

            imageReader = ImageReader.newInstance(width, height, ImageFormat.YUV_420_888, 2)

            virtualDisplay = mediaProjection!!.createVirtualDisplay(
                "ScreenCast",
                width, height, dpi,
                DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
                imageReader!!.surface, null, null
            )

            isRunning = true
            serverThread = Thread {
                startMjpegServer()
            }
            serverThread?.start()
        } catch (e: Exception) {
            e.printStackTrace()
            stopCapture()
        }
    }

    private fun stopCapture() {
        isRunning = false
        try { serverSocket?.close() } catch (e: Exception) {}
        serverSocket = null
        virtualDisplay?.release()
        virtualDisplay = null
        imageReader?.close()
        imageReader = null
        mediaProjection?.stop()
        mediaProjection = null
        handlerThread?.quitSafely()
        handlerThread = null
        handler = null
        stopForeground(true)
    }

    private fun startMjpegServer() {
        try {
            serverSocket = ServerSocket(PORT)
            while (isRunning && !serverSocket!!.isClosed) {
                try {
                    val client = serverSocket!!.accept()
                    handler?.post {
                        handleClient(client)
                    }
                } catch (e: Exception) {
                    if (isRunning) e.printStackTrace()
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun handleClient(client: Socket) {
        try {
            val out = java.io.DataOutputStream(client.outputStream)

            out.writeBytes("HTTP/1.1 200 OK\r\n")
            out.writeBytes("Connection: close\r\n")
            out.writeBytes("Content-Type: multipart/x-mixed-replace; boundary=--frameboundary\r\n")
            out.writeBytes("\r\n")
            out.flush()

            while (isRunning && !client.isClosed) {
                val frame = captureFrame(70)
                if (frame != null) {
                    out.writeBytes("\r\n--frameboundary\r\n")
                    out.writeBytes("Content-Type: image/jpeg\r\n")
                    out.writeBytes("Content-Length: ${frame.size}\r\n")
                    out.writeBytes("\r\n")
                    out.write(frame)
                    out.flush()
                }
                Thread.sleep(33)
            }
        } catch (e: Exception) {
        } finally {
            try { client.close() } catch (e: Exception) {}
        }
    }

    private fun captureFrame(quality: Int): ByteArray? {
        return try {
            val image = imageReader?.acquireLatestImage() ?: return null
            val w = image.width
            val h = image.height

            // YUV_420_888 has multiple planes; convert to JPEG via YuvImage
            val yuvImage = YuvImage(
                image.planes[0].buffer.array(),
                ImageFormat.NV21, w, h, null
            )
            val output = ByteArrayOutputStream()
            yuvImage.compressToJpeg(Rect(0, 0, w, h), quality, output)
            image.close()
            output.toByteArray()
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }

    private fun createNotification(text: String): Notification {
        val channel = NotificationChannel(CHANNEL_ID, "Screen Cast", NotificationManager.IMPORTANCE_LOW)
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.createNotificationChannel(channel)

        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = android.app.PendingIntent.getActivity(this, 0, intent, android.app.PendingIntent.FLAG_IMMUTABLE)

        return android.app.Notification.Builder(this, CHANNEL_ID)
            .setContentTitle("ScreenCast")
            .setContentText(text)
            .setSmallIcon(android.R.drawable.ic_media_play)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()
    }
}