//  SignalingClient.swift
//  ScreenCast

import Foundation

protocol SignalingClientDelegate: AnyObject {
    func signalingClient(_ client: SignalingClient, didReceiveMessage message: SignalingMessage)
    func signalingClientDidConnect(_ client: SignalingClient)
    func signalingClient(_ client: SignalingClient, didDisconnectWithError error: Error?)
}

class SignalingClient {
    private let url: URL
    private var webSocketTask: URLSessionWebSocketTask?
    private let urlSession: URLSession
    private let queue = DispatchQueue(label: "com.screencast.signaling")
    private var pingTimer: Timer?
    private var isConnected = false

    weak var delegate: SignalingClientDelegate?

    init(url: URL) {
        self.url = url
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        self.urlSession = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
    }

    func connect() {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.webSocketTask = self.urlSession.webSocketTask(with: self.url)
            self.webSocketTask?.resume()
            self.receiveMessage()
            self.startPing()
        }
    }

    func disconnect() {
        queue.async { [weak self] in
            self?.stopPing()
            self?.webSocketTask?.cancel(with: .goingAway, reason: nil)
            self?.webSocketTask = nil
            self?.isConnected = false
        }
    }

    func send(_ message: SignalingMessage) {
        queue.async { [weak self] in
            guard let self = self, self.isConnected else { return }
            do {
                let data = try JSONEncoder().encode(message)
                let string = String(data: data, encoding: .utf8)!
                let message = URLSessionWebSocketTask.Message.string(string)
                self.webSocketTask?.send(message) { error in
                    if let error = error {
                        print("Send error: \(error)")
                    }
                }
            } catch {
                print("Encode error: \(error)")
            }
        }
    }

    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                print("Receive error: \(error)")
                self.handleDisconnect(error: error)
            case .success(let message):
                switch message {
                case .string(let text):
                    self.handleMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self.handleMessage(text)
                    }
                @unknown default:
                    break
                }
                self.receiveMessage()
            }
        }
    }

    private func handleMessage(_ text: String) {
        do {
            let message = try JSONDecoder().decode(SignalingMessage.self, from: Data(text.utf8))
            DispatchQueue.main.async {
                self.delegate?.signalingClient(self, didReceiveMessage: message)
            }
        } catch {
            print("Decode error: \(error), text: \(text)")
        }
    }

    private func startPing() {
        pingTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.send(.ping)
        }
    }

    private func stopPing() {
        pingTimer?.invalidate()
        pingTimer = nil
    }

    private func handleDisconnect(error: Error?) {
        isConnected = false
        stopPing()
        DispatchQueue.main.async {
            self.delegate?.signalingClient(self, didDisconnectWithError: error)
        }
    }
}