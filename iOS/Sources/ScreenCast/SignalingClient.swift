//  SignalingClient.swift
//  ScreenCast

import Foundation

protocol SignalingClientDelegate: AnyObject {
    func signalingClient(_ client: SignalingClient, didReceiveMessage message: String)
    func signalingClientDidConnect(_ client: SignalingClient)
    func signalingClient(_ client: SignalingClient, didDisconnectWithError error: Error?)
}

class SignalingClient {
    weak var delegate: SignalingClientDelegate?

    init(url: URL) {}

    func connect() {
        delegate?.signalingClientDidConnect(self)
    }

    func disconnect() {}
}