//  SignalingMessage.swift
//  ScreenCast

import Foundation

enum SignalingMessage {
    case offer(sdp: String)
    case answer(sdp: String)
    case iceCandidate(candidate: String, sdpMid: String, sdpMLineIndex: Int32)
    case ready(width: Int, height: Int, dpi: Int)
    case error(message: String)
    case ping
    case pong
}