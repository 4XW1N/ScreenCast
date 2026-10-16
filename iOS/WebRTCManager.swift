//  WebRTCManager.swift
//  ScreenCast

import Foundation

protocol WebRTCManagerDelegate: AnyObject {
    func webRTCManager(_ manager: WebRTCManager, didChangeConnectionState state: String)
    func webRTCManager(_ manager: WebRTCManager, didEncounterError error: Error)
}

class WebRTCManager: NSObject {
    weak var delegate: WebRTCManagerDelegate?

    func connect(to url: URL) {
        delegate?.webRTCManager(self, didChangeConnectionState: "disconnected")
    }

    func disconnect() {}
}