package com.screencast

import android.app.Application
import org.webrtc.PeerConnectionFactory

class ScreenCastApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        // Initialize WebRTC
        PeerConnectionFactory.initialize(
            PeerConnectionFactory.InitializationOptions.builder(this)
                .setEnableInternalTracer(true)
                .createInitializationOptions()
        )
    }
}