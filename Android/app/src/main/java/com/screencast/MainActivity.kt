package com.screencast

import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.net.wifi.WifiInfo
import android.net.wifi.WifiManager
import android.os.Bundle
import android.widget.Button
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity

class MainActivity : AppCompatActivity() {

    private lateinit var mediaProjectionManager: MediaProjectionManager
    private lateinit var statusText: TextView
    private lateinit var ipText: TextView
    private lateinit var startButton: Button
    private var isCasting = false

    private val REQUEST_CODE = 1001

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        mediaProjectionManager = getSystemService(MediaProjectionManager::class.java)

        statusText = findViewById(R.id.statusText)
        ipText = findViewById(R.id.ipText)
        startButton = findViewById(R.id.startButton)

        // Show IP address
        val wifiManager = getSystemService(WifiManager::class.java) as WifiManager
        val wifiInfo = wifiManager.connectionInfo
        val ip = intToIp(wifiInfo.ipAddress)
        ipText.text = "Cast to: http://$ip:8080/stream on iPad"

        startButton.setOnClickListener {
            if (!isCasting) {
                val intent = mediaProjectionManager.createScreenCaptureIntent()
                startActivityForResult(intent, REQUEST_CODE)
            } else {
                stopCasting()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CODE && resultCode == RESULT_OK) {
            data?.let { intent ->
                val serviceIntent = Intent(this, ScreenCastService::class.java).apply {
                    putExtra("mediaProjectionResultCode", resultCode)
                    putExtra("mediaProjectionData", data)
                }
                startForegroundService(serviceIntent)
                isCasting = true
                startButton.text = "Stop Casting"
                startButton.isEnabled = true
                statusText.text = "Casting... Open http://${getIpAddress()}:8080/stream on iPad"
                statusText.setTextColor(android.graphics.Color.GREEN)
            }
        } else {
            Toast.makeText(this, "Screen capture permission required", Toast.LENGTH_SHORT).show()
        }
    }

    private fun stopCasting() {
        val intent = Intent(this, ScreenCastService::class.java)
        stopService(intent)
        isCasting = false
        startButton.text = "Start Casting"
        startButton.isEnabled = true
        statusText.text = "Not casting"
        statusText.setTextColor(android.graphics.Color.RED)
    }

    private fun getIpAddress(): String {
        val wifiManager = getSystemService(WifiManager::class.java) as WifiManager
        val ip = wifiManager.connectionInfo.ipAddress
        return intToIp(ip)
    }

    private fun intToIp(ipInt: Int): String {
        return "${(ipInt and 0xFF)}.${(ipInt shr 8 and 0xFF)}.${(ipInt shr 16 and 0xFF)}.${(ipInt shr 24 and 0xFF)}"
    }

    override fun onDestroy() {
        super.onDestroy()
        if (isCasting) {
            stopService(Intent(this, ScreenCastService::class.java))
        }
    }
}