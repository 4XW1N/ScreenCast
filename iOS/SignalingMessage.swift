//  SignalingMessage.swift
//  ScreenCast

import Foundation

enum SignalingMessage: Codable {
    case offer(sdp: String)
    case answer(sdp: String)
    case iceCandidate(candidate: String, sdpMid: String, sdpMLineIndex: Int32)
    case ready(width: Int, height: Int, dpi: Int)
    case error(message: String)
    case ping
    case pong

    enum CodingKeys: String, CodingKey {
        case type
    }

    enum MessageType: String, Codable {
        case offer, answer, iceCandidate = "ice-candidate", ready, error, ping, pong
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(MessageType.self, forKey: .type)

        switch type {
        case .offer:
            let sdp = try decoder.container(keyedBy: DataKeys.self).decode(String.self, forKey: .sdp)
            self = .offer(sdp: sdp)
        case .answer:
            let sdp = try decoder.container(keyedBy: DataKeys.self).decode(String.self, forKey: .sdp)
            self = .answer(sdp: sdp)
        case .iceCandidate:
            let data = try decoder.container(keyedBy: DataKeys.self)
            let candidate = try data.decode(String.self, forKey: .candidate)
            let sdpMid = try data.decode(String.self, forKey: .sdpMid)
            let sdpMLineIndex = try data.decode(Int32.self, forKey: .sdpMLineIndex)
            self = .iceCandidate(candidate: candidate, sdpMid: sdpMid, sdpMLineIndex: sdpMLineIndex)
        case .ready:
            let data = try decoder.container(keyedBy: DataKeys.self)
            let width = try data.decode(Int.self, forKey: .width)
            let height = try data.decode(Int.self, forKey: .height)
            let dpi = try data.decode(Int.self, forKey: .dpi)
            self = .ready(width: width, height: height, dpi: dpi)
        case .error:
            let message = try decoder.container(keyedBy: DataKeys.self).decode(String.self, forKey: .message)
            self = .error(message: message)
        case .ping:
            self = .ping
        case .pong:
            self = .pong
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .offer(let sdp):
            try container.encode(MessageType.offer, forKey: .type)
            var data = encoder.container(keyedBy: DataKeys.self)
            try data.encode(sdp, forKey: .sdp)
        case .answer(let sdp):
            try container.encode(MessageType.answer, forKey: .type)
            var data = encoder.container(keyedBy: DataKeys.self)
            try data.encode(sdp, forKey: .sdp)
        case .iceCandidate(let candidate, let sdpMid, let sdpMLineIndex):
            try container.encode(MessageType.iceCandidate, forKey: .type)
            var data = encoder.container(keyedBy: DataKeys.self)
            try data.encode(candidate, forKey: .candidate)
            try data.encode(sdpMid, forKey: .sdpMid)
            try data.encode(sdpMLineIndex, forKey: .sdpMLineIndex)
        case .ready(let width, let height, let dpi):
            try container.encode(MessageType.ready, forKey: .type)
            var data = encoder.container(keyedBy: DataKeys.self)
            try data.encode(width, forKey: .width)
            try data.encode(height, forKey: .height)
            try data.encode(dpi, forKey: .dpi)
        case .error(let message):
            try container.encode(MessageType.error, forKey: .type)
            var data = encoder.container(keyedBy: DataKeys.self)
            try data.encode(message, forKey: .message)
        case .ping:
            try container.encode(MessageType.ping, forKey: .type)
        case .pong:
            try container.encode(MessageType.pong, forKey: .type)
        }
    }

    private enum DataKeys: String, CodingKey {
        case sdp, candidate, sdpMid, sdpMLineIndex, width, height, dpi, message
    }

    var type: String {
        switch self {
        case .offer: return "offer"
        case .answer: return "answer"
        case .iceCandidate: return "ice-candidate"
        case .ready: return "ready"
        case .error: return "error"
        case .ping: return "ping"
        case .pong: return "pong"
        }
    }
}