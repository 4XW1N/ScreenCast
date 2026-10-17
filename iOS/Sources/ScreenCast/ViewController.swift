//  ViewController.swift
//  ScreenCast for iPad

import UIKit

class ViewController: UIViewController {

    private var imageView: UIImageView!
    private var ipTextField: UITextField!
    private var portTextField: UITextField!
    private var connectButton: UIButton!
    private var disconnectButton: UIButton!
    private var statusLabel: UILabel!
    private var titleLabel: UILabel!
    private var deviceView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.92, green: 0.94, blue: 0.98, alpha: 1.0)
        setupUI()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        let isLandscape = view.bounds.width > view.bounds.height
        UIView.animate(withDuration: 0.3) {
            self.arrangeForOrientation(isLandscape: isLandscape)
        }
    }

    // MARK: - UI Setup

    private func setupUI() {
        // Main container
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)

        // Title
        titleLabel = UILabel()
        titleLabel.text = "ScreenCast"
        titleLabel.font = .systemFont(ofSize: 48, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = UIColor(red: 0.25, green: 0.13, blue: 0.93, alpha: 1.0)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(titleLabel)

        // Subtitle
        let subtitle = UILabel()
        subtitle.text = "Cast Android Phone to iPad"
        subtitle.font = .systemFont(ofSize: 20, weight: .medium)
        subtitle.textAlignment = .center
        subtitle.textColor = .secondaryLabel
        subtitle.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(subtitle)

        // Control panel (top section)
        let controlPanel = UIView()
        controlPanel.backgroundColor = .white
        controlPanel.layer.cornerRadius = 20
        controlPanel.layer.shadowColor = UIColor.black.cgColor
        controlPanel.layer.shadowOffset = CGSize(width: 0, height: 4)
        controlPanel.layer.shadowRadius = 12
        controlPanel.layer.shadowOpacity = 0.1
        controlPanel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(controlPanel)

        // IP Input
        let ipLabel = UILabel()
        ipLabel.text = "Android IP Address"
        ipLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        ipLabel.textColor = .label
        ipLabel.translatesAutoresizingMaskIntoConstraints = false
        controlPanel.addSubview(ipLabel)

        ipTextField = UITextField()
        ipTextField.placeholder = "192.168.1.50"
        ipTextField.borderStyle = .roundedRect
        ipTextField.font = .systemFont(ofSize: 20)
        ipTextField.autocapitalizationType = .none
        ipTextField.keyboardType = .numbersAndPunctuation
        ipTextField.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.97, alpha: 1.0)
        ipTextField.translatesAutoresizingMaskIntoConstraints = false
        controlPanel.addSubview(ipTextField)

        // Port Input
        let portLabel = UILabel()
        portLabel.text = "Port"
        portLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        portLabel.textColor = .label
        portLabel.translatesAutoresizingMaskIntoConstraints = false
        controlPanel.addSubview(portLabel)

        portTextField = UITextField()
        portTextField.placeholder = "8080"
        portTextField.borderStyle = .roundedRect
        portTextField.font = .systemFont(ofSize: 20)
        portTextField.keyboardType = .numberPad
        portTextField.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.97, alpha: 1.0)
        portTextField.translatesAutoresizingMaskIntoConstraints = false
        controlPanel.addSubview(portTextField)

        // Connect Button
        connectButton = UIButton(type: .system)
        connectButton.setTitle("🔗 Connect", for: .normal)
        connectButton.titleLabel?.font = .systemFont(ofSize: 22, weight: .bold)
        connectButton.backgroundColor = UIColor(red: 0.20, green: 0.60, blue: 0.86, alpha: 1.0)
        connectButton.setTitleColor(.white, for: .normal)
        connectButton.layer.cornerRadius = 14
        connectButton.heightAnchor.constraint(equalToConstant: 60).isActive = true
        connectButton.addTarget(self, action: #selector(connectTapped), for: .touchUpInside)
        connectButton.translatesAutoresizingMaskIntoConstraints = false
        controlPanel.addSubview(connectButton)

        // Disconnect Button
        disconnectButton = UIButton(type: .system)
        disconnectButton.setTitle("⏹ Disconnect", for: .normal)
        disconnectButton.titleLabel?.font = .systemFont(ofSize: 22, weight: .bold)
        disconnectButton.backgroundColor = .systemRed
        disconnectButton.setTitleColor(.white, for: .normal)
        disconnectButton.layer.cornerRadius = 14
        disconnectButton.heightAnchor.constraint(equalToConstant: 60).isActive = true
        disconnectButton.addTarget(self, action: #selector(disconnectTapped), for: .touchUpInside)
        disconnectButton.isHidden = true
        disconnectButton.translatesAutoresizingMaskIntoConstraints = false
        controlPanel.addSubview(disconnectButton)

        // Status
        statusLabel = UILabel()
        statusLabel.text = "Ready to connect"
        statusLabel.textAlignment = .center
        statusLabel.font = .systemFont(ofSize: 20, weight: .medium)
        statusLabel.textColor = .secondaryLabel
        statusLabel.numberOfLines = 0
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(statusLabel)

        // Video Display Area
        deviceView = UIView()
        deviceView.backgroundColor = .black
        deviceView.layer.cornerRadius = 20
        deviceView.layer.borderWidth = 3
        deviceView.layer.borderColor = UIColor.systemGray4.cgColor
        deviceView.clipsToBounds = true
        deviceView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(deviceView)

        imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .clear
        imageView.translatesAutoresizingMaskIntoConstraints = false
        deviceView.addSubview(imageView)

        // Placeholder text in video area
        let placeholderLabel = UILabel()
        placeholderLabel.text = "📱\nAndroid screen will appear here"
        placeholderLabel.font = .systemFont(ofSize: 24, weight: .medium)
        placeholderLabel.textColor = .systemGray3
        placeholderLabel.textAlignment = .center
        placeholderLabel.numberOfLines = 0
        placeholderLabel.tag = 999
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        deviceView.addSubview(placeholderLabel)

        NSLayoutConstraint.activate([
            placeholderLabel.centerXAnchor.constraint(equalTo: deviceView.centerXAnchor),
            placeholderLabel.centerYAnchor.constraint(equalTo: deviceView.centerYAnchor)
        ])

        // Constraints
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 30),
            titleLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),

            subtitle.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitle.centerXAnchor.constraint(equalTo: container.centerXAnchor),

            controlPanel.topAnchor.constraint(equalTo: subtitle.bottomAnchor, constant: 30),
            controlPanel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 40),
            controlPanel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -40),

            ipLabel.topAnchor.constraint(equalTo: controlPanel.topAnchor, constant: 24),
            ipLabel.leadingAnchor.constraint(equalTo: controlPanel.leadingAnchor, constant: 24),
            ipLabel.trailingAnchor.constraint(equalTo: controlPanel.trailingAnchor, constant: -24),

            ipTextField.topAnchor.constraint(equalTo: ipLabel.bottomAnchor, constant: 8),
            ipTextField.leadingAnchor.constraint(equalTo: controlPanel.leadingAnchor, constant: 24),
            ipTextField.trailingAnchor.constraint(equalTo: controlPanel.trailingAnchor, constant: -24),
            ipTextField.heightAnchor.constraint(equalToConstant: 56),

            portLabel.topAnchor.constraint(equalTo: ipTextField.bottomAnchor, constant: 12),
            portLabel.leadingAnchor.constraint(equalTo: controlPanel.leadingAnchor, constant: 24),

            portTextField.topAnchor.constraint(equalTo: portLabel.bottomAnchor, constant: 8),
            portTextField.leadingAnchor.constraint(equalTo: controlPanel.leadingAnchor, constant: 24),
            portTextField.widthAnchor.constraint(equalToConstant: 100),
            portTextField.heightAnchor.constraint(equalToConstant: 56),

            connectButton.topAnchor.constraint(equalTo: portTextField.bottomAnchor, constant: 20),
            connectButton.leadingAnchor.constraint(equalTo: controlPanel.leadingAnchor, constant: 24),
            connectButton.trailingAnchor.constraint(equalTo: controlPanel.trailingAnchor, constant: -24),
            connectButton.bottomAnchor.constraint(equalTo: controlPanel.bottomAnchor, constant: -24),

            disconnectButton.topAnchor.constraint(equalTo: connectButton.topAnchor),
            disconnectButton.leadingAnchor.constraint(equalTo: connectButton.leadingAnchor),
            disconnectButton.trailingAnchor.constraint(equalTo: connectButton.trailingAnchor),
            disconnectButton.bottomAnchor.constraint(equalTo: connectButton.bottomAnchor),

            statusLabel.topAnchor.constraint(equalTo: controlPanel.bottomAnchor, constant: 16),
            statusLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),

            deviceView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 16),
            deviceView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            deviceView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            deviceView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20),

            imageView.topAnchor.constraint(equalTo: deviceView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: deviceView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: deviceView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: deviceView.bottomAnchor)
        ])
    }

    @objc private func connectTapped() {
        guard let ip = ipTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !ip.isEmpty else {
            showAlert("Please enter Android IP address")
            return
        }
        let port = portTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "8080"

        statusLabel.text = "Connecting to \(ip):\(port)..."
        statusLabel.textColor = .systemBlue

        let urlString = "http://\(ip):\(port)/stream"
        guard let url = URL(string: urlString) else {
            showAlert("Invalid URL")
            return
        }

        // Remove placeholder
        if let placeholder = deviceView.viewWithTag(999) {
            placeholder.removeFromSuperview()
        }

        // Create URLSession for MJPEG streaming
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        let task = session.dataTask(with: url)
        task.resume()
    }

    @objc private func disconnectTapped() {
        isConnected = false
        connectButton.isHidden = false
        disconnectButton.isHidden = true
        imageView.image = nil

        // Add placeholder back
        if deviceView.viewWithTag(999) == nil {
            let placeholder = UILabel()
            placeholder.text = "Android screen will appear here"
            placeholder.font = .systemFont(ofSize: 24)
            placeholder.textColor = .systemGray3
            placeholder.textAlignment = .center
            placeholder.numberOfLines = 0
            placeholder.tag = 999
            placeholder.translatesAutoresizingMaskIntoConstraints = false
            deviceView.addSubview(placeholder)
            NSLayoutConstraint.activate([
                placeholder.centerXAnchor.constraint(equalTo: deviceView.centerXAnchor),
                placeholder.centerYAnchor.constraint(equalTo: deviceView.centerYAnchor),
                placeholder.leadingAnchor.constraint(equalTo: deviceView.leadingAnchor, constant: 20),
                placeholder.trailingAnchor.constraint(equalTo: deviceView.trailingAnchor, constant: -20)
            ])
        }

        statusLabel.text = "Disconnected"
        statusLabel.textColor = .secondaryLabel
    }

    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: "ScreenCast", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - URLSessionDataDelegate for MJPEG
extension ViewController: URLSessionDataDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        buffer.append(data)

        // JPEG start marker: 0xFF 0xD8
        // JPEG end marker: 0xFF 0xD9
        while let startRange = buffer.range(of: Data([0xFF, 0xD8, 0xFF])) {
            guard let endRange = buffer.range(of: Data([0xFF, 0xD9]), in: startRange.lowerBound..<buffer.count) else {
                break
            }

            let end = endRange.upperBound
            let jpegData = buffer.subdata(in: startRange.lowerBound..<end)
            buffer.removeSubrange(0..<end)

            if let image = UIImage(data: jpegData) {
                DispatchQueue.main.async {
                    self.imageView.image = image
                    if self.statusLabel.text != "Connected - Streaming" {
                        self.statusLabel.text = "Connected - Streaming"
                        self.statusLabel.textColor = .systemGreen
                    }
                }
            }
        }

        // Prevent buffer from growing too large
        if buffer.count > 5_000_000 {
            buffer.removeFirst(1_000_000)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        DispatchQueue.main.async {
            if let error = error {
                self.statusLabel.text = "Error: \(error.localizedDescription)"
                self.statusLabel.textColor = .systemRed
            }
        }
    }
}