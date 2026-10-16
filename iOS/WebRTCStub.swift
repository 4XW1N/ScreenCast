// WebRTCStub.swift
// Stub implementations for WebRTC classes
// Replace with real WebRTC framework when available

import Foundation
import UIKit

// MARK: - Core Types

public class RTCPeerConnectionFactory {
    public init() {}
    public func videoEncoderFactory() -> RTCDefaultVideoEncoderFactory { RTCDefaultVideoEncoderFactory() }
    public func videoDecoderFactory() -> RTCDefaultVideoDecoderFactory { RTCDefaultVideoDecoderFactory() }
}

public class RTCDefaultVideoEncoderFactory: NSObject {}
public class RTCDefaultVideoDecoderFactory: NSObject {}

public class RTCConfiguration: NSObject {
    public var iceServers: [RTCIceServer] = []
    public var sdpSemantics: String = "unified-plan"
}

public class RTCIceServer: NSObject {
    public var urlStrings: [String] = []
    public init(urlStrings: [String]) { self.urlStrings = urlStrings }
}

public class RTCMediaConstraints: NSObject {
    public init(mandatoryConstraints: [String: String]? = nil, optionalConstraints: [String: String]? = nil) {}
}

public class RTCSessionDescription: NSObject {
    public enum SessionType: String { case offer, answer, prAnswer }
    public let type: SessionType
    public let sdp: String
    public init(type: SessionType, sdp: String) { self.type = type; self.sdp = sdp }
}

public class RTCIceCandidate: NSObject {
    public let sdp: String
    public let sdpMLineIndex: Int32
    public let sdpMid: String?
    public init(sdp: String, sdpMLineIndex: Int32, sdpMid: String?) {
        self.sdp = sdp; self.sdpMLineIndex = sdpMLineIndex; self.sdpMid = sdpMid
    }
}

// MARK: - Video

public class RTCVideoTrack: NSObject {
    public func add(_ renderer: RTCVideoRenderer) {}
    public func remove(_ renderer: RTCVideoRenderer) {}
}

public class RTCVideoRenderer: NSObject {}

public class RTCVideoFrame: NSObject {
    public var width: Int32 = 0
    public var height: Int32 = 0
}

// MARK: - Peer Connection

public class RTCPeerConnection: NSObject {
    public weak var delegate: RTCPeerConnectionDelegate?

    public init(configuration: RTCConfiguration, constraints: RTCMediaConstraints) {}

    public func offer(for constraints: RTCMediaConstraints, completionHandler: @escaping (RTCSessionDescription?, Error?) -> Void) {
        completionHandler(nil, NSError(domain: "WebRTCStub", code: -1, userInfo: [NSLocalizedDescriptionKey: "WebRTC not available"]))
    }

    public func answer(for constraints: RTCMediaConstraints, completionHandler: @escaping (RTCSessionDescription?, Error?) -> Void) {
        completionHandler(nil, NSError(domain: "WebRTCStub", code: -1, userInfo: [NSLocalizedDescriptionKey: "WebRTC not available"]))
    }

    public func setLocalDescription(_ sdp: RTCSessionDescription, completionHandler: @escaping (Error?) -> Void) {
        completionHandler(NSError(domain: "WebRTCStub", code: -1, userInfo: [NSLocalizedDescriptionKey: "WebRTC not available"]))
    }

    public func setRemoteDescription(_ sdp: RTCSessionDescription, completionHandler: @escaping (Error?) -> Void) {
        completionHandler(NSError(domain: "WebRTCStub", code: -1, userInfo: [NSLocalizedDescriptionKey: "WebRTC not available"]))
    }

    public func add(_ candidate: RTCIceCandidate) {}
    public func close() {}
}

public protocol RTCPeerConnectionDelegate: AnyObject {
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: Int)
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream)
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream)
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection)
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: Int)
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: Int)
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate)
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate])
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel)
}

public class RTCMediaStream: NSObject {}
public class RTCDataChannel: NSObject {}

// MARK: - Metal Video View

public class RTCMTLVideoView: UIView, RTCVideoRenderer {
    public var videoContentMode: UIView.ContentMode = .scaleAspectFit
    public func setSize(_ size: CGSize) {}
}

public protocol RTCVideoViewDelegate: AnyObject {
    func videoView(_ videoView: RTCVideoRenderer, didChangeVideoSize size: CGSize)
}
