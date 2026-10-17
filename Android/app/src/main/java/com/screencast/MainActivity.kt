package com.screencast

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.os.Bundle
import android.widget.Button
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import java.net.Inet4Address
import java.net.NetworkInterface

class MainActivity : AppCompatActivity() {

    private lateinit var mediaProjectionManager: MediaProjectionManager
    private lateinit var ipText: TextView
    private lateinit var statusText: TextView
    private lateinit var startButton: Button
    private var isCasting = false

    private val REQUEST_CODE = 1001

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        mediaProjectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager

        ipText = findViewById(R.id.ipText)
        statusText = findViewById(R.id.statusText)
        startButton = findViewById(R.id.startButton)

        // Show IP address on launch
        displayIpAddress()

        startButton.setOnClickListener {
            if (!isCasting) {
                val intent = mediaProjectionManager.createScreenCaptureIntent()
                startActivityForResult(intent, REQUEST_CODE)
            } else {
                stopCasting()
            }
        }
    }

    private fun displayIpAddress() {
        try {
            val ip = getLocalIpAddress()
            if (ip != null) {
                ipText.text = ip
            } else {
                ipText.text = "Not connected"
            }
        } catch (e: Exception) {
            ipText.text = "Error"
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