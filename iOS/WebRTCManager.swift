//  WebRTCManager.swift
//  ScreenCast

import Foundation
import WebRTC

protocol WebRTCManagerDelegate: AnyObject {
    func webRTCManager(_ manager: WebRTCManager, didChangeConnectionState state: RTCIceConnectionState)
    func webRTCManager(_ manager: WebRTCManager, didReceiveRemoteVideoTrack track: RTCVideoTrack)
    func webRTCManager(_ manager: WebRTCManager, didEncounterError error: Error)
}

class WebRTCManager: NSObject {
    private var peerConnection: RTCPeerConnection?
    private var peerConnectionFactory: RTCPeerConnectionFactory?
    private let videoEncoderFactory: RTCVideoEncoderFactory
    private let videoDecoderFactory: RTCVideoDecoderFactory
    private var localVideoTrack: RTCVideoTrack?
    private var remoteVideoTrack: RTCVideoTrack?
    
    weak var delegate: WebRTCManagerDelegate?
    private let signalingClient: SignalingClient

    init(signalingClient: SignalingClient) {
        self.signalingClient = signalingClient
        self.videoEncoderFactory = RTCDefaultVideoEncoderFactory()
        self.videoDecoderFactory = RTCDefaultVideoDecoderFactory()
        super.init()
        
        setupPeerConnectionFactory()
        setupSignaling()
    }

    private func setupPeerConnectionFactory() {
        let encoderFactory = RTCDefaultVideoEncoderFactory()
        let decoderFactory = RTCDefaultVideoDecoderFactory()
        peerConnectionFactory = RTCPeerConnectionFactory(
            encoderFactory: encoderFactory,
            decoderFactory: decoderFactory
        )
    }

    private func setupSignaling() {
        signalingClient.delegate = self
    }

    func connect(to url: URL) {
        signalingClient.connect()
    }

    func disconnect() {
        signalingClient.disconnect()
        cleanup()
    }

    private func createPeerConnection() {
        let config = RTCConfiguration()
        config.iceServers = [RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])]
        config.sdpSemantics = .unifiedPlan
        config.continualGatheringPolicy = .gatherContinually

        let constraints = RTCMediaConstraints(
            mandatoryConstraints: [],
            optionalConstraints: [
                "DtlsSrtpKeyAgreement": "true"
            ]
        )

        peerConnection = peerConnectionFactory?.peerConnection(
            with: config,
            constraints: constraints,
            delegate: self
        )
    }

    private func createOffer() {
        let constraints = RTCMediaConstraints(
            mandatoryConstraints: [
                "OfferToReceiveAudio": "false",
                "OfferToReceiveVideo": "true"
            ],
            optionalConstraints: []
        )

        peerConnection?.offer(for: constraints) { [weak self] sdp, error in
            guard let self = self else { return }
            if let error = error {
                self.delegate?.webRTCManager(self, didEncounterError: error)
                return
            }
            guard let sdp = sdp else { return }
            self.peerConnection?.setLocalDescription(sdp) { error in
                if let error = error {
                    self.delegate?.webRTCManager(self, didEncounterError: error)
                    return
                }
                self.signalingClient.send(.offer(sdp: sdp.sdp))
            }
        }
    }

    private func handleRemoteSDP(_ sdp: RTCSessionDescription) {
        peerConnection?.setRemoteDescription(sdp) { [weak self] error in
            if let error = error {
                self?.delegate?.webRTCManager(self!, didEncounterError: error)
            }
        }
    }

    private func handleIceCandidate(_ candidate: RTCIceCandidate) {
        peerConnection?.add(candidate)
    }

    private func cleanup() {
        peerConnection?.close()
        peerConnection = nil
        localVideoTrack = nil
        remoteVideoTrack = nil
    }
}

extension WebRTCManager: SignalingClientDelegate {
    func signalingClient(_ client: SignalingClient, didReceiveMessage message: SignalingMessage) {
        switch message {
        case .answer(let sdp):
            let sessionDescription = RTCSessionDescription(type: .answer, sdp: sdp)
            handleRemoteSDP(sessionDescription)
        case .iceCandidate(let candidate, let sdpMid, let sdpMLineIndex):
            let iceCandidate = RTCIceCandidate(sdp: candidate, sdpMLineIndex: sdpMLineIndex, sdpMid: sdpMid)
            handleIceCandidate(iceCandidate)
        case .ready(let width, let height, let dpi):
            print("Receiver ready: \(width)x\(height) @ \(dpi)dpi")
        case .error(let message):
            print("Signaling error: \(message)")
        case .ping:
            client.send(.pong)
        default:
            break
        }
    }

    func signalingClientDidConnect(_ client: SignalingClient) {
        print("Signaling connected")
        createPeerConnection()
        createOffer()
    }

    func signalingClient(_ client: SignalingClient, didDisconnectWithError error: Error?) {
        print("Signaling disconnected: \(error?.localizedDescription ?? "unknown")")
        cleanup()
    }
}

extension WebRTCManager: RTCPeerConnectionDelegate {
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        print("Signaling state: \(stateChanged)")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        print("Remote stream added")
        if let videoTrack = stream.videoTracks.first {
            remoteVideoTrack = videoTrack
            DispatchQueue.main.async {
                self.delegate?.webRTCManager(self, didReceiveRemoteVideoTrack: videoTrack)
            }
        }
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        print("Remote stream removed")
    }

    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        print("Should negotiate")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        print("ICE connection state: \(newState)")
        DispatchQueue.main.async {
            self.delegate?.webRTCManager(self, didChangeConnectionState: newState)
        }
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        print("ICE gathering state: \(newState)")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        signalingClient.send(.iceCandidate(
            candidate: candidate.sdp,
            sdpMid: candidate.sdpMid ?? "",
            sdpMLineIndex: candidate.sdpMLineIndex
        ))
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {}
}