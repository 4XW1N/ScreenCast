package com.screencast

import android.content.Context
import android.util.Log
import org.webrtc.*
import java.util.*

class PeerConnectionManager(
    private val context: Context,
    private val rootEglBase: EglBase,
    private val signalingClient: SignalingClient,
    private val screenCaptureManager: ScreenCaptureManager,
    private val onStateChange: (PeerConnection.PeerConnectionState) -> Unit,
    private val onError: (String) -> Unit
) {

    private val TAG = "PeerConnectionManager"
    private var peerConnection: PeerConnection? = null
    private var peerConnectionFactory: PeerConnectionFactory? = null
    private var localVideoTrack: VideoTrack? = null

    fun initialize(width: Int, height: Int, dpi: Int) {
        // Create PeerConnectionFactory
        val options = PeerConnectionFactory.Options()
        val videoEncoderFactory = DefaultVideoEncoderFactory(rootEglBase.context, true, true)
        val videoDecoderFactory = DefaultVideoDecoderFactory(rootEglBase.context)

        peerConnectionFactory = PeerConnectionFactory.builder()
            .setOptions(options)
            .setVideoEncoderFactory(videoEncoderFactory)
            .setVideoDecoderFactory(videoDecoderFactory)
            .createPeerConnectionFactory()

        // Set up signaling callbacks
        signalingClient.onMessage = this::handleSignalingMessage
        signalingClient.onConnected = this::onSignalingConnected
        signalingClient.onDisconnected = { error ->
            onError("Signaling disconnected: $error")
            cleanup()
        }
    }

    private fun onSignalingConnected() {
        Log.d(TAG, "Signaling connected, creating peer connection")
        createPeerConnection()
    }

    private fun createPeerConnection() {
        val rtcConfig = PeerConnection.RTCConfiguration(
            listOf(PeerConnection.IceServer("stun:stun.l.google.com:19302"))
        ).apply {
            tcpCandidatePolicy = PeerConnection.TcpCandidatePolicy.DISABLED
            bundlePolicy = PeerConnection.BundlePolicy.MAXBUNDLE
            rtcpMuxPolicy = PeerConnection.RtcpMuxPolicy.REQUIRE
            continualGatheringPolicy = PeerConnection.ContinualGatheringPolicy.GATHER_CONTINUALLY
        }

        val constraints = MediaConstraints().apply {
            mandatory.add(MediaConstraints.KeyValuePair("OfferToReceiveAudio", "false"))
            mandatory.add(MediaConstraints.KeyValuePair("OfferToReceiveVideo", "true"))
        }

        peerConnection = peerConnectionFactory!!.createPeerConnection(
            rtcConfig, constraints, object : CustomPeerConnectionObserver() {
                override fun onIceCandidate(candidate: IceCandidate) {
                    signalingClient.send(SignalingMessage.IceCandidate(
                        candidate.sdp, candidate.sdpMid!!, candidate.sdpMLineIndex
                    ))
                }

                override fun onConnectionChange(newState: PeerConnection.PeerConnectionState) {
                    Log.d(TAG, "Connection state: $newState")
                    onStateChange(newState)
                }

                override fun onIceConnectionChange(newState: PeerConnection.IceConnectionState) {
                    Log.d(TAG, "ICE state: $newState")
                    if (newState == PeerConnection.IceConnectionState.FAILED) {
                        peerConnection?.restartIce()
                    }
                }

                override fun onAddStream(stream: MediaStream) {
                    Log.d(TAG, "Remote stream added: ${stream.id}")
                }
            }
        )

        // Add local video track
        localVideoTrack?.let { peerConnection!!.addTrack(it, listOf("screenStream")) }
    }

    fun startCaptureAndOffer(mediaProjection: MediaProjection, width: Int, height: Int, dpi: Int) {
        localVideoTrack = screenCaptureManager.startCapture(mediaProjection, width, height, dpi)
        
        if (peerConnection != null) {
            createOffer()
        }
    }

    private fun createOffer() {
        val constraints = MediaConstraints().apply {
            mandatory.add(MediaConstraints.KeyValuePair("OfferToReceiveAudio", "false"))
            mandatory.add(MediaConstraints.KeyValuePair("OfferToReceiveVideo", "true"))
        }

        peerConnection!!.createOffer(object : SdpObserver {
            override fun onCreateSuccess(sessionDescription: SessionDescription) {
                peerConnection!!.setLocalDescription(object : SdpObserver {
                    override fun onCreateSuccess(desc: SessionDescription?) {}
                    override fun onSetSuccess() {
                        signalingClient.send(SignalingMessage.Offer(
                            sessionDescription.description, sessionDescription.type.canonicalForm()
                        ))
                    }
                    override fun onCreateFailure(error: String) { onError("Offer creation failed: $error") }
                    override fun onSetFailure(error: String) { onError("Set local desc failed: $error") }
                }, sessionDescription)
            }
            override fun onSetSuccess() {}
            override fun onCreateFailure(error: String) { onError("Create offer failed: $error") }
            override fun onSetFailure(error: String) { onError("Set local failed: $error") }
        }, constraints)
    }

    private fun handleSignalingMessage(message: SignalingMessage) {
        when (message) {
            is SignalingMessage.Answer -> {
                val sdp = SessionDescription(SessionDescription.Type.fromCanonicalForm(message.type), message.sdp)
                peerConnection?.setRemoteDescription(object : SdpObserver {
                    override fun onCreateSuccess(desc: SessionDescription?) {}
                    override fun onSetSuccess() { Log.d(TAG, "Remote description set") }
                    override fun onCreateFailure(error: String) { onError("Answer create failed: $error") }
                    override fun onSetFailure(error: String) { onError("Set remote failed: $error") }
                }, sdp)
            }
            is SignalingMessage.IceCandidate -> {
                val candidate = IceCandidate(message.sdpMid, message.sdpMLineIndex, message.candidate)
                peerConnection?.addIceCandidate(candidate)
            }
            is SignalingMessage.Ready -> {
                Log.d(TAG, "Receiver ready: ${message.width}x${message.height}")
            }
            is SignalingMessage.Error -> {
                onError("Server error: ${message.message}")
            }
        }
    }

    fun stop() {
        cleanup()
        signalingClient.disconnect()
    }

    private fun cleanup() {
        localVideoTrack?.dispose()
        localVideoTrack = null
        peerConnection?.close()
        peerConnection = null
        peerConnectionFactory?.dispose()
        peerConnectionFactory = null
    }
}