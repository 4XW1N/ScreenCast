package com.screencast

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.os.Bundle
import android.util.Log
import android.widget.Button
import android.widget.EditText
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.screencast.databinding.ActivityMainBinding
import org.webrtc.EglBase

class MainActivity : AppCompatActivity() {

    private val TAG = "MainActivity"
    private lateinit var binding: ActivityMainBinding
    private lateinit var mediaProjectionManager: MediaProjectionManager
    private var isCasting = false

    private val REQUEST_MEDIA_PROJECTION = 1001
    private val PERMISSION_RECORD_AUDIO = 1002

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        mediaProjectionManager = getSystemService(MediaProjectionManager::class.java)

        binding.toggleButton.setOnClickListener { toggleCasting() }
        binding.ipInput.setText(getSavedIp())
        binding.portInput.setText(getSavedPort().toString())
    }

    private fun toggleCasting() {
        if (isCasting) {
            stopCasting()
        } else {
            startCasting()
        }
    }

    private fun startCasting() {
        val ip = binding.ipInput.text.toString().trim()
        val port = binding.portInput.text.toString().trim().toIntOrNull() ?: 8888

        if (ip.isEmpty()) {
            Toast.makeText(this, "Enter iPad IP address", Toast.LENGTH_SHORT).show()
            return
        }

        saveIp(ip)
        savePort(port)

        if (ContextCompat.checkSelfPermission(this, android.Manifest.permission.RECORD_AUDIO)
            != android.content.pm.PackageManager.PERMISSION_GRANTED
        ) {
            ActivityCompat.requestPermissions(this,
                arrayOf(android.Manifest.permission.RECORD_AUDIO), PERMISSION_RECORD_AUDIO)
            return
        }

        updateStatus(getString(R.string.status_requesting))
        binding.progressBar.visibility = android.view.View.VISIBLE
        binding.toggleButton.isEnabled = false

        val intent = mediaProjectionManager.createScreenCaptureIntent()
        startActivityForResult(intent, REQUEST_MEDIA_PROJECTION)
    }

    private fun stopCasting() {
        val intent = Intent(this, CaptureService::class.java)
        stopService(intent)
        isCasting = false
        updateUI()
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_MEDIA_PROJECTION && resultCode == Activity.RESULT_OK) {
            data?.let { resultData ->
                updateStatus(getString(R.string.status_connecting))
                val serviceIntent = Intent(this, CaptureService::class.java).apply {
                    putExtra(MediaProjectionManager.EXTRA_MEDIA_PROJECTION, resultData)
                    putExtra("ip_address", binding.ipInput.text.toString().trim())
                    putExtra("port", binding.portInput.text.toString().toIntOrNull() ?: 8888)
                }
                ContextCompat.startForegroundService(this, serviceIntent)
                isCasting = true
                updateUI()
            }
        } else {
            Toast.makeText(this, getString(R.string.permission_denied), Toast.LENGTH_SHORT).show()
            updateStatus(getString(R.string.status_idle))
            binding.progressBar.visibility = android.view.View.GONE
            binding.toggleButton.isEnabled = true
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_RECORD_AUDIO) {
            if (grantResults.isNotEmpty() && grantResults[0] == android.content.pm.PackageManager.PERMISSION_GRANTED) {
                startCasting()
            } else {
                Toast.makeText(this, "Audio permission required for screen capture", Toast.LENGTH_SHORT).show()
                binding.progressBar.visibility = android.view.View.GONE
                binding.toggleButton.isEnabled = true
            }
        }
    }

    private fun updateUI() {
        binding.toggleButton.text = if (isCasting) getString(R.string.stop_casting) else getString(R.string.start_casting)
        binding.toggleButton.isEnabled = true
        binding.progressBar.visibility = android.view.View.GONE
        binding.ipInput.isEnabled = !isCasting
        binding.portInput.isEnabled = !isCasting
    }

    private fun updateStatus(message: String) {
        binding.statusText.text = message
    }

    private fun getSavedIp(): String {
        return getSharedPreferences("prefs", Context.MODE_PRIVATE).getString("ip", "") ?: ""
    }

    private fun saveIp(ip: String) {
        getSharedPreferences("prefs", Context.MODE_PRIVATE).edit().putString("ip", ip).apply()
    }

    private fun getSavedPort(): Int {
        return getSharedPreferences("prefs", Context.MODE_PRIVATE).getInt("port", 8888)
    }

    private fun savePort(port: Int) {
        getSharedPreferences("prefs", Context.MODE_PRIVATE).edit().putInt("port", port).apply()
    }
}