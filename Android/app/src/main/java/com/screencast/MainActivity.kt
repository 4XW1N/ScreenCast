package com.screencast

import android.app.Activity
import android.app.AlertDialog
import android.content.Context
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.widget.Button
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.core.app.NotificationManagerCompat
import java.net.Inet4Address
import java.net.NetworkInterface

class MainActivity : AppCompatActivity() {

    private lateinit var mediaProjectionManager: MediaProjectionManager
    private lateinit var ipText: TextView
    private lateinit var portText: TextView
    private lateinit var statusText: TextView
    private lateinit var startButton: Button
    private var isCasting = false

    private val REQUEST_CODE = 1001
    private val CAST_PORT = 8080
    private val NOTIF_PERMISSION_CODE = 2001

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        mediaProjectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager

        ipText = findViewById(R.id.ipText)
        portText = findViewById(R.id.portText)
        statusText = findViewById(R.id.statusText)
        startButton = findViewById(R.id.startButton)

        // Show IP address and port on launch
        displayIpAddress()

        // Android 13+: request notification permission (required for foreground service)
        if (Build.VERSION.SDK_INT >= 33 && !NotificationManagerCompat.from(this).areNotificationsEnabled()) {
            requestPermissions(arrayOf(android.Manifest.permission.POST_NOTIFICATIONS), NOTIF_PERMISSION_CODE)
        }

        startButton.setOnClickListener {
            if (!isCasting) {
                // Check if notifications are enabled (required for foreground service on Android 8+)
                if (!NotificationManagerCompat.from(this).areNotificationsEnabled()) {
                    // Notifications are blocked - warn user
                    AlertDialog.Builder(this)
                        .setTitle("Notifications Required")
                        .setMessage("ScreenCast needs notifications enabled to run the streaming service. Please enable notifications for this app in Settings, then try again.")
                        .setPositiveButton("Open Settings") { _, _ ->
                            val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                                putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                            }
                            startActivity(intent)
                        }
                        .setNegativeButton("Try Anyway") { _, _ ->
                            startCastingFlow()
                        }
                        .setCancelable(false)
                        .show()
                } else {
                    startCastingFlow()
                }
            } else {
                stopCasting()
            }
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == NOTIF_PERMISSION_CODE) {
            if (NotificationManagerCompat.from(this).areNotificationsEnabled()) {
                statusText.text = "Notifications enabled - tap Start Casting"
                statusText.setTextColor(android.graphics.Color.parseColor("#4CAF50"))
            } else {
                statusText.text = "Notifications blocked - enable in Settings"
                statusText.setTextColor(android.graphics.Color.parseColor("#F44336"))
            }
        }
    }

    private fun startCastingFlow() {
        val intent = mediaProjectionManager.createScreenCaptureIntent()
        startActivityForResult(intent, REQUEST_CODE)
    }

    private fun displayIpAddress() {
        try {
            val ip = getLocalIpAddress()
            if (ip != null) {
                ipText.text = ip
                portText.text = "Port: $CAST_PORT"
            } else {
                ipText.text = "Not connected"
                portText.text = "Port: $CAST_PORT"
            }
        } catch (e: Exception) {
            ipText.text = "Error"
            portText.text = "Port: $CAST_PORT"
        }
    }

    private fun getLocalIpAddress(): String? {
        try {
            val interfaces = NetworkInterface.getNetworkInterfaces()
            while (interfaces.hasMoreElements()) {
                val networkInterface = interfaces.nextElement()
                val addresses = networkInterface.inetAddresses
                while (addresses.hasMoreElements()) {
                    val address = addresses.nextElement()
                    if (!address.isLoopbackAddress && address is Inet4Address) {
                        return address.hostAddress
                    }
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return null
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        android.util.Log.i("MainActivity", "onActivityResult requestCode=$requestCode resultCode=$resultCode data=${data != null}")
        if (requestCode == REQUEST_CODE && resultCode == Activity.RESULT_OK) {
            // Start streaming service with projection data
            val serviceIntent = Intent(this, ScreenCastService::class.java).apply {
                putExtra("mediaProjectionResultCode", resultCode)
                putExtra("mediaProjectionData", data)
            }
            startForegroundService(serviceIntent)
            isCasting = true
            startButton.text = "Stop Casting"
            statusText.text = "Casting live..."
            statusText.setTextColor(getColor(android.R.color.holo_green_dark))
        } else {
            statusText.text = "Permission denied"
            statusText.setTextColor(getColor(android.R.color.holo_red_dark))
        }
    }

    private fun stopCasting() {
        val intent = Intent(this, ScreenCastService::class.java)
        stopService(intent)
        isCasting = false
        startButton.text = "Start Casting"
        statusText.text = "Ready to cast"
        statusText.setTextColor(getColor(android.R.color.darker_gray))
    }

    override fun onDestroy() {
        super.onDestroy()
        if (isCasting) {
            stopService(Intent(this, ScreenCastService::class.java))
        }
    }

    override fun onResume() {
        super.onResume()
        displayIpAddress()
    }
}