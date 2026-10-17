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
import android.util.Log
import android.view.Surface
import android.view.WindowManager
import java.io.ByteArrayOutputStream
import java.io.DataOutputStream
import java.net.ServerSocket
import java.net.Socket

class ScreenCastService : Service() {

    private val TAG = "ScreenCastService"

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
        Log.i(TAG, "onStartCommand called")
        // Start foreground - notifications required on Android 8+
        try {
            startForeground(NOTIFICATION_ID, createNotification("ScreenCast - Starting..."))
        } catch (e: Exception) {
            Log.e(TAG, "startForeground failed", e)
            // Notifications blocked - server may still work briefly but Android may kill service
        }

        try {
            val resultCode = intent.getIntExtra("mediaProjectionResultCode", Int.MIN_VALUE)
            val data = intent.getParcelableExtra<Intent>("mediaProjectionData")
            Log.i(TAG, "resultCode=$resultCode data=${data != null} isRunning=$isRunning")

            if (resultCode != android.app.Activity.RESULT_OK || data == null || isRunning) {
                Log.w(TAG, "Missing projection data or already running, returning")
                return START_STICKY
            }

            mediaProjectionManager = getSystemService(MediaProjectionManager::class.java)
            mediaProjection = mediaProjectionManager?.getMediaProjection(resultCode, data)

            if (mediaProjection == null) {
                Log.e(TAG, "mediaProjection is null")
                return START_STICKY
            }

            startCapture()
        } catch (e: Exception) {
            Log.e(TAG, "onStartCommand error", e)
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
            Log.i(TAG, "startCapture ${width}x$height dpi=$dpi")

            handlerThread = HandlerThread("ScreenCastHandler")
            handlerThread?.start()
            handler = android.os.Handler(handlerThread!!.looper)

            // Android 14 (API 34) requires a registered callback before creating the virtual display
            mediaProjection!!.registerCallback(object : MediaProjection.Callback() {
                override fun onStop() {
                    Log.w(TAG, "MediaProjection onStop")
                    isRunning = false
                }
            }, handler)

            imageReader = ImageReader.newInstance(width, height, ImageFormat.YUV_420_888, 2)
            Log.i(TAG, "imageReader created")

            virtualDisplay = mediaProjection!!.createVirtualDisplay(
                "ScreenCast",
                width, height, dpi,
                DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
                imageReader!!.surface, null, null
            )
            Log.i(TAG, "virtualDisplay created: ${virtualDisplay != null}")

            isRunning = true
            serverThread = Thread {
                startMjpegServer()
            }
            serverThread?.start()
        } catch (e: Exception) {
            Log.e(TAG, "startCapture failed", e)
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
            Log.i(TAG, "MJPEG server listening on port $PORT")
            // Notify that server is ready
            startForeground(NOTIFICATION_ID, createNotification("ScreenCast - Server ready on port $PORT"))
            while (isRunning && !serverSocket!!.isClosed) {
                try {
                    val client = serverSocket!!.accept()
                    Log.i(TAG, "client connected: ${client.inetAddress}")
                    Thread {
                        handleClient(client)
                    }.start()
                } catch (e: Exception) {
                    if (isRunning) Log.e(TAG, "accept error", e)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Server failed to start", e)
            startForeground(NOTIFICATION_ID, createNotification("ScreenCast - Server failed: ${e.message}"))
        }
    }

    private fun handleClient(client: Socket) {
        try {
            val out = java.io.DataOutputStream(client.outputStream)

            out.writeBytes("HTTP/1.1 200 OK\r\n")
            out.writeBytes("Content-Type: multipart/x-mixed-replace; boundary=frameboundary\r\n")
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

    private var frameCount = 0

    private fun captureFrame(quality: Int): ByteArray? {
        return try {
            val image = imageReader?.acquireLatestImage()
            if (image == null) {
                if (frameCount < 3) Log.w(TAG, "acquireLatestImage returned null (frameCount=$frameCount)")
                return null
            }
            val w = image.width
            val h = image.height
            val nv21 = yuv420ToNv21(image)
            image.close()

            val yuvImage = YuvImage(nv21, ImageFormat.NV21, w, h, null)
            val output = ByteArrayOutputStream()
            yuvImage.compressToJpeg(Rect(0, 0, w, h), quality, output)
            val bytes = output.toByteArray()
            frameCount++
            if (frameCount <= 3) Log.i(TAG, "frame #$frameCount ${w}x$h jpeg=${bytes.size} bytes")
            bytes
        } catch (e: Exception) {
            Log.e(TAG, "captureFrame failed", e)
            null
        }
    }

    private fun yuv420ToNv21(image: Image): ByteArray {
        val width = image.width
        val height = image.height
        val yPlane = image.planes[0]
        val uPlane = image.planes[1]
        val vPlane = image.planes[2]

        val yBuffer = yPlane.buffer
        val uBuffer = uPlane.buffer
        val vBuffer = vPlane.buffer

        val yRowStride = yPlane.rowStride
        val uvRowStride = uPlane.rowStride
        val uvPixelStride = uPlane.pixelStride

        val nv21 = ByteArray(width * height * 3 / 2)

        // Copy the Y plane
        val yRow = ByteArray(yRowStride)
        var pos = 0
        for (r in 0 until height) {
            yBuffer.position(r * yRowStride)
            val remaining = yBuffer.remaining()
            val toRead = minOf(yRowStride, remaining)
            yBuffer.get(yRow, 0, toRead)
            System.arraycopy(yRow, 0, nv21, pos, width)
            pos += width
        }

        // Interleave V and U planes (NV21 = V then U)
        val uvHeight = height / 2
        val uvWidth = width / 2
        var uvPos = width * height
        for (r in 0 until uvHeight) {
            for (c in 0 until uvWidth) {
                val uIndex = r * uvRowStride + c * uvPixelStride
                val vIndex = r * vPlane.rowStride + c * vPlane.pixelStride
                nv21[uvPos++] = vBuffer.get(vIndex)
                nv21[uvPos++] = uBuffer.get(uIndex)
            }
        }
        return nv21
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