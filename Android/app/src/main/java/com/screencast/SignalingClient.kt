package com.screencast

import android.util.Log
import kotlinx.coroutines.*
import okhttp3.*
import org.json.JSONObject
import org.webrtc.*
import java.net.URI

class SignalingClient(
    private val serverUrl: String,
    private val onMessage: (SignalingMessage) -> Unit,
    private val onConnected: () -> Unit,
    private val onDisconnected: (String?) -> Unit
) {
    private val client = OkHttpClient.Builder()
        .pingInterval(10, java.util.concurrent.TimeUnit.SECONDS)
        .build()

    private var webSocket: WebSocket? = null
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private val TAG = "SignalingClient"

    fun connect() {
        scope.launch {
            val request = Request.Builder().url(serverUrl).build()
            webSocket = client.newWebSocket(request, object : WebSocketListener() {
                override fun onOpen(webSocket: WebSocket, response: Response) {
                    Log.d(TAG, "WebSocket connected")
                    scope.launch(Dispatchers.Main) { onConnected() }
                }

                override fun onMessage(webSocket: WebSocket, text: String) {
                    Log.d(TAG, "Received: $text")
                    val msg = SignalingMessage.fromJson(text)
                    msg?.let { scope.launch(Dispatchers.Main) { onMessage(it) } }
                }

                override fun onMessage(webSocket: WebSocket, bytes: okio.ByteString) {
                    // Binary messages not used
                }

                override fun onClosing(webSocket: WebSocket, code: Int, reason: String) {
                    webSocket.close(1000, null)
                    scope.launch(Dispatchers.Main) { onDisconnected("Closed: $reason") }
                }

                override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
                    Log.e(TAG, "WebSocket error", t)
                    scope.launch(Dispatchers.Main) { onDisconnected(t.message) }
                }
            })
        }
    }

    fun send(message: SignalingMessage) {
        val json = com.google.gson.Gson().toJson(message)
        webSocket?.send(json) ?: Log.w(TAG, "WebSocket not connected, dropping: $json")
    }

    fun disconnect() {
        webSocket?.close(1000, "Client disconnect")
        scope.cancel()
    }
}