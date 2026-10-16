package com.screencast

import android.content.Context
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.net.wifi.WifiInfo
import android.net.wifi.WifiManager
import android.os.Bundle
import android.os.Handler
import android.widget.Button
import android.widget.Switch
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.google.android.material.card.MaterialCardView

class MainActivity : AppCompatActivity() {

    private lateinit var mediaProjectionManager: MediaProjectionManager
    private lateinit var statusText: TextView
    private lateinit var ipText: TextView
    private lateinit var startButton: Button
    private lateinit var qualitySwitch: Switch
    private lateinit var cardView: MaterialCardView
    private var isCasting = false
    private var pulseHandler: Handler? = null
    private var pulseState = false

    private val REQUEST_CODE = 1001

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        mediaProjectionManager = getSystemService(MediaProjectionManager::class.java)

        statusText = findViewById(R.id.statusText)
        ipText = findViewById(R.id.ipText)
        startButton = findViewById(R.id.startButton)
        qualitySwitch = findViewById(R.id.qualitySwitch)
        cardView = findViewById(R.id.cardView)

        updateIpDisplay()

        startButton.setOnClickListener {
            if (!isCasting) {
                requestScreenCapture()
            } else {
                stopCasting()
            }
        }

        ipText.setOnClickListener {
            Toast.makeText(this@MainActivity, "IP copied to clipboard", Toast.LENGTH_SHORT).show()
        }
    }

    private fun updateIpDisplay() {
        val wifiManager = getSystemService(WifiManager::class.java) as WifiManager
        val wifiInfo = wifiManager.connectionInfo
        val ip = intToIp(wifiInfo.ipAddress)
        ipText.text = "http://$ip:8080/stream"
    }

    private fun requestScreenCapture() {
        val intent = mediaProjectionManager.createScreenCaptureIntent()
        startActivityForResult(intent, REQUEST_CODE)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CODE && resultCode == RESULT_OK) {
            data?.let { intent ->
                val serviceIntent = Intent(this@MainActivity, ScreenCastService::class.java).apply {
                    putExtra("mediaProjectionResultCode", resultCode)
                    putExtra("mediaProjectionData", intent)
                    putExtra("quality", qualitySwitch.isChecked)
                }
                startForegroundService(serviceIntent)
                isCasting = true
                updateUIForCasting(true)
                startPulseAnimation()
            }
        } else {
            Toast.makeText(this@MainActivity, "Screen capture permission required", Toast.LENGTH_SHORT).show()
        }
    }

    private fun stopCasting() {
        val intent = Intent(this@MainActivity, ScreenCastService::class.java)
        stopService(intent)
        isCasting = false
        updateUIForCasting(false)
        stopPulseAnimation()
    }

    private fun updateUIForCasting(casting: Boolean) {
        if (casting) {
            startButton.text = "⏹ Stop Casting"
            startButton.setBackgroundColor(android.graphics.Color.RED)
            statusText.text = "🔴 Casting Live"
            statusText.setTextColor(android.graphics.Color.GREEN)
            cardView.setCardBackgroundColor(android.graphics.Color.parseColor("#E8F5E9"))
        } else {
            startButton.text = "▶ Start Casting"
            startButton.setBackgroundColor(android.graphics.Color.parseColor("#6200EE"))
            statusText.text = "⚪ Ready to Cast"
            statusText.setTextColor(android.graphics.Color.GRAY)
            cardView.setCardBackgroundColor(android.graphics.Color.WHITE)
        }
    }

    private fun startPulseAnimation() {
        pulseHandler = Handler()
        val runnable = object : Runnable {
            override fun run() {
                val color = if (pulseState) android.graphics.Color.parseColor("#E8F5E9") else android.graphics.Color.parseColor("#C8E6C9")
                pulseState = !pulseState
                cardView.setCardBackgroundColor(color)
                pulseHandler?.postDelayed(this, 500)
            }
        }
        pulseHandler?.post(runnable)
    }

    private fun stopPulseAnimation() {
        pulseHandler?.removeCallbacksAndMessages(null)
        pulseState = false
        cardView.setCardBackgroundColor(android.graphics.Color.WHITE)
    }

    private fun intToIp(ipInt: Int): String {
        return "${(ipInt and 0xFF)}.${(ipInt shr 8 and 0xFF)}.${(ipInt shr 16 and 0xFF)}.${(ipInt shr 24 and 0xFF)}"
    }

    override fun onDestroy() {
        super.onDestroy()
        stopPulseAnimation()
        if (isCasting) {
            stopService(Intent(this@MainActivity, ScreenCastService::class.java))
        }
    }

    override fun onResume() {
        super.onResume()
        updateIpDisplay()
    }
}