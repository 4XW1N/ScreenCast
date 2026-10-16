//  ViewController.swift
//  ScreenCast

import UIKit


class ViewController: UIViewController {
    
    private let videoRenderView = VideoRenderView()
    private let statusLabel = UILabel()
    private let ipTextField = UITextField()
    private let portTextField = UITextField()
    private let startButton = UIButton(type: .system)
    private let stopButton = UIButton(type: .system)
    private let stackView = UIStackView()
    
    private var webRTCManager: WebRTCManager?
    private var signalingClient: SignalingClient?
    private var isReceiving = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadSavedSettings()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "ScreenCast Receiver"
        
        // Video render view
        videoRenderView.backgroundColor = .black
        videoRenderView.layer.cornerRadius = 12
        videoRenderView.clipsToBounds = true
        
        // Status label
        statusLabel.text = "Ready to receive"
        statusLabel.textAlignment = .center
        statusLabel.textColor = .secondaryLabel
        statusLabel.font = .systemFont(ofSize: 16)
        statusLabel.numberOfLines = 0
        
        // IP Text Field
        ipTextField.placeholder = "Android IP Address (e.g., 192.168.1.50)"
        ipTextField.borderStyle = .roundedRect
        ipTextField.autocapitalizationType = .none
        ipTextField.keyboardType = .numbersAndPunctuation
        ipTextField.clearButtonMode = .whileEditing
        
        // Port Text Field
        portTextField.placeholder = "Port (default: 8888)"
        portTextField.borderStyle = .roundedRect
        portTextField.keyboardType = .numberPad
        portTextField.text = "8888"
        
        // Start Button
        startButton.setTitle("Start Receiving", for: .normal)
        startButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        startButton.backgroundColor = .systemBlue
        startButton.setTitleColor(.white, for: .normal)
        startButton.layer.cornerRadius = 12
        startButton.addTarget(self, action: #selector(startReceiving), for: .touchUpInside)
        
        // Stop Button
        stopButton.setTitle("Stop Receiving", for: .normal)
        stopButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        stopButton.backgroundColor = .systemRed
        stopButton.setTitleColor(.white, for: .normal)
        stopButton.layer.cornerRadius = 12
        stopButton.addTarget(self, action: #selector(stopReceiving), for: .touchUpInside)
        stopButton.isHidden = true
        
        // Stack View
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.addArrangedSubview(videoRenderView)
        stackView.addArrangedSubview(statusLabel)
        stackView.addArrangedSubview(ipTextField)
        stackView.addArrangedSubview(portTextField)
        stackView.addArrangedSubview(startButton)
        stackView.addArrangedSubview(stopButton)
        
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            
            videoRenderView.heightAnchor.constraint(equalTo: videoRenderView.widthAnchor, multiplier: 9.0/16.0),
            startButton.heightAnchor.constraint(equalToConstant: 50),
            stopButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func loadSavedSettings() {
        let defaults = UserDefaults.standard
        ipTextField.text = defaults.string(forKey: "android_ip") ?? ""
        portTextField.text = defaults.string(forKey: "android_port") ?? "8888"
    }
    
    private func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(ipTextField.text, forKey: "android_ip")
        defaults.set(portTextField.text, forKey: "android_port")
    }
    
    @objc private func startReceiving() {
        guard let ip = ipTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !ip.isEmpty else {
            showAlert("Please enter Android IP address")
            return
        }
        
        let port = Int(portTextField.text ?? "8888") ?? 8888
        saveSettings()
        
        let wsURL = URL(string: "ws://\(ip):\(port)/ws")!
        
        signalingClient = SignalingClient(url: wsURL)
        webRTCManager = WebRTCManager(signalingClient: signalingClient!)
        webRTCManager?.delegate = self
        
        updateStatus("Connecting to Android...")
        startButton.isHidden = true
        stopButton.isHidden = false
        ipTextField.isEnabled = false
        portTextField.isEnabled = false
        
        webRTCManager?.connect(to: wsURL)
    }
    
    @objc private func stopReceiving() {
        webRTCManager?.disconnect()
        webRTCManager = nil
        signalingClient = nil
        
        videoRenderView.removeVideoTrack()
        updateStatus("Ready to receive")
        startButton.isHidden = false
        stopButton.isHidden = true
        ipTextField.isEnabled = true
        portTextField.isEnabled = true
    }
    
    private func updateStatus(_ message: String) {
        DispatchQueue.main.async {
            self.statusLabel.text = message
        }
    }
    
    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: "ScreenCast", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension ViewController: WebRTCManagerDelegate {
    func webRTCManager(_ manager: WebRTCManager, didChangeConnectionState state: RTCIceConnectionState) {
        switch state {
        case .connected, .completed:
            updateStatus("Connected - Receiving screen")
        case .connecting:
            updateStatus("Connecting...")
        case .disconnected:
            updateStatus("Disconnected")
        case .failed:
            updateStatus("Connection failed")
            stopReceiving()
        case .closed:
            updateStatus("Connection closed")
            stopReceiving()
        case .new:
            updateStatus("New connection")
        case .count:
            break
        @unknown default:
            updateStatus("Unknown state: \(state)")
        }
    }
    
    func webRTCManager(_ manager: WebRTCManager, didReceiveRemoteVideoTrack track: RTCVideoTrack) {
        DispatchQueue.main.async {
            self.videoRenderView.setVideoTrack(track)
        }
    }
    
    func webRTCManager(_ manager: WebRTCManager, didEncounterError error: Error) {
        DispatchQueue.main.async {
            self.updateStatus("Error: \(error.localizedDescription)")
            self.showAlert(error.localizedDescription)
        }
    }
}