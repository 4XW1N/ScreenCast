package com.screencast

// Stub implementations for WebRTC classes
// Replace with real WebRTC dependency when available

class PeerConnectionFactory {
    class InitializationOptions {
        companion object {
            fun builder(context: android.content.Context) = InitializationOptions()
            fun setEnableInternalTracer(enable: Boolean) = this
            fun createInitializationOptions() = this
        }
    }

    class Options

    companion object {
        fun initialize(options: InitializationOptions) {}
        fun builder() = PeerConnectionFactoryBuilder()
    }

    fun createVideoSource(screencast: Boolean) = VideoSource()
    fun createVideoTrack(id: String, source: VideoSource) = VideoTrack()
    fun createPeerConnection(config: Any?, constraints: Any?, observer: Any?) = PeerConnection()
    fun dispose() {}
}

class PeerConnectionFactoryBuilder {
    fun setOptions(options: PeerConnectionFactory.Options) = this
    fun setVideoEncoderFactory(factory: Any) = this
    fun setVideoDecoderFactory(factory: Any) = this
    fun createPeerConnectionFactory() = PeerConnectionFactory()
}

class VideoSource {
    fun adaptOutputFormat(width: Int, height: Int, framerate: Int) {}
    fun getCapturerObserver() = CapturerObserver()
    fun dispose() {}
}

class CapturerObserver

class VideoTrack {
    var isEnabled: Boolean = true
    fun dispose() {}
}

class PeerConnection {
    fun close() {}
}

class EglBase {
    companion object {
        fun create() = EglBase()
    }
    val context: Any = Any()
    fun release() {}
}

class ScreenCapturerAndroid(
    mediaProjection: android.media.projection.MediaProjection,
    listener: ScreenCaptureListener
) {
    interface ScreenCaptureListener {
        fun onScreenCaptureStarted() {}
        fun onScreenCaptureStopped() {}
        fun onScreenCaptureError(error: String) {}
    }

    fun startCapture(width: Int, height: Int, framerate: Int) {}
    fun initialize(context: Any, observer: CapturerObserver) {}
    fun stopCapture() {}
    fun dispose() {}
}

class DefaultVideoEncoderFactory(context: Any, enableIntelVp8Encoder: Boolean, enableH264HighProfile: Boolean)
class DefaultVideoDecoderFactory(context: Any)

class CustomPeerConnectionObserver : PeerConnection.Observer {
    override fun onIceCandidate(candidate: IceCandidate) {}
    override fun onConnectionChange(newState: PeerConnection.PeerConnectionState) {}
    override fun onIceConnectionChange(newState: PeerConnection.IceConnectionState) {}
    override fun onSignalingChange(newState: PeerConnection.SignalingState) {}
    override fun onAddStream(stream: org.webrtc.MediaStream) {}
    override fun onRemoveStream(stream: org.webrtc.MediaStream) {}
    override fun onDataChannel(channel: org.webrtc.DataChannel) {}
    override fun onRenegotiationNeeded() {}
    override fun onAddTrack(receiver: org.webrtc.RtpReceiver, streams: Array<out org.webrtc.MediaStream>) {}
}

open class PeerConnection {
    interface Observer {
        fun onSignalingChange(newState: SignalingState) {}
        fun onAddStream(stream: org.webrtc.MediaStream) {}
        fun onRemoveStream(stream: org.webrtc.MediaStream) {}
        fun onDataChannel(channel: org.webrtc.DataChannel) {}
        fun onRenegotiationNeeded() {}
        fun onIceCandidate(candidate: IceCandidate) {}
        fun onIceConnectionChange(newState: IceConnectionState) {}
        fun onConnectionChange(newState: PeerConnectionState) {}
        fun onIceConnectionReceivingChange(receiving: Boolean) {}
        fun onIceGatheringChange(newState: IceGatheringState) {}
        fun onAddTrack(receiver: org.webrtc.RtpReceiver, streams: Array<out org.webrtc.MediaStream>) {}
        fun onTrack(transceiver: org.webrtc.RtpTransceiver) {}
    }

    enum class PeerConnectionState { NEW, CONNECTING, CONNECTED, DISCONNECTED, FAILED, CLOSED }
    enum class IceConnectionState { NEW, CHECKING, CONNECTED, COMPLETED, FAILED, DISCONNECTED, CLOSED }
    enum class SignalingState { STABLE, HAVE_LOCAL_OFFER, HAVE_LOCAL_PRANSWER, HAVE_REMOTE_OFFER, HAVE_REMOTE_PRANSWER, CLOSED }
    enum class IceGatheringState { NEW, GATHERING, COMPLETE }
    enum class TcpCandidatePolicy { ENABLED, DISABLED }
    enum class BundlePolicy { BALANCED, MAXBUNDLE, MAXCOMPAT }
    enum class RtcpMuxPolicy { NEGOTIATE, REQUIRE }
    enum class ContinualGatheringPolicy { GATHER_ONCE, GATHER_CONTINUALLY }

    class RTCConfiguration(val iceServers: List<IceServer>)
    class IceServer(val urls: List<String>)
}

open class IceCandidate(val sdpMid: String, val sdpMLineIndex: Int, val sdp: String)

class SessionDescription(val type: Type, val sdp: String) {
    enum class Type { OFFER, PRANSWER, ANSWER }
    fun canonicalForm() = type.name.lowercase()
}

interface SdpObserver {
    fun onCreateSuccess(desc: SessionDescription?) {}
    fun onSetSuccess() {}
    fun onCreateFailure(error: String) {}
    fun onSetFailure(error: String) {}
}

class MediaConstraints {
    val mandatory = mutableListOf<Pair<String, String>>()
    val optional = mutableListOf<Pair<String, String>>()
    fun addMandatory(key: String, value: String) { mandatory.add(key to value) }
    fun addOptional(key: String, value: String) { optional.add(key to value) }
}

class VideoCapturer {
    interface FrameCallback {
        fun onFrame(frame: Any) {}
    }
}

class TextureBufferImpl(width: Int, height: Int, eglContext: Any) {
    fun release() {}
}

class VideoFrame {
    class Builder {
        fun setTextureBuffer(buffer: Any) = this
        fun setRotation(rotation: Int) = this
        fun setTimestampNs(timestampNs: Long) = this
        fun build() = VideoFrame()
    }
}