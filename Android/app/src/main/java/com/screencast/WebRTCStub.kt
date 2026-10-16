package com.screencast

// Stub implementations for WebRTC classes

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

open class IceCandidate(val sdpMid: String, val sdpMLineIndex: Int, val sdp: String)

open class SessionDescription(val type: Type, val sdp: String) {
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

// Enum stubs for connection states
enum class PeerConnectionState { NEW, CONNECTING, CONNECTED, DISCONNECTED, FAILED, CLOSED }
enum class IceConnectionState { NEW, CHECKING, CONNECTED, COMPLETED, FAILED, DISCONNECTED, CLOSED }
enum class SignalingState { STABLE, HAVE_LOCAL_OFFER, HAVE_LOCAL_PRANSWER, HAVE_REMOTE_OFFER, HAVE_REMOTE_PRANSWER, CLOSED }
enum class IceGatheringState { NEW, GATHERING, COMPLETE }

class RTCConfiguration(val iceServers: List<IceServer>)
class IceServer(val urls: List<String>)