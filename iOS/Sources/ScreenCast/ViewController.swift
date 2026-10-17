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

    private var session: URLSession?
    private var dataTask: URLSessionDataTask?
    private var isConnected = false
    private var buffer = Data()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadSavedSettings()
    }

    private func setupUI() {
        // Header
        let headerStack = UIStackView()
        headerStack.axis = .vertical
        headerStack.alignment = .center
        headerStack.spacing = 8
        headerStack.translatesAutoresizingMaskIntoConstraints = false

        let iconLabel = UILabel()
        iconLabel.text = "📱"
        iconLabel.font = .systemFont(ofSize: 48)

        let titleLabel = UILabel()
        titleLabel.text = "ScreenCast Receiver"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = .label

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Receive Android screen on iPad"
        subtitleLabel.font = .systemFont(ofSize: 16)
        subtitleLabel.textColor = .secondaryLabel

        headerStack.addArrangedSubview(iconLabel)
        headerStack.addArrangedSubview(titleLabel)
        headerStack.addArrangedSubview(subtitleLabel)
        view.addSubview(headerStack)

        // IP Text Field
        ipTextField = UITextField()
        ipTextField.placeholder = "Android IP Address"
        ipTextField.borderStyle = .roundedRect
        ipTextField.autocapitalizationType = .none
        ipTextField.keyboardType = .numbersAndPunctuation
        ipTextField.backgroundColor = .white
        ipTextField.translatesAutoresizingMaskIntoConstraints = false

        // Port Input
        portTextField = UITextField()
        portTextField.placeholder = "8080"
        portTextField.borderStyle = .roundedRect
        portTextField.keyboardType = .numberPad
        portTextField.text = "8080"
        portTextField.backgroundColor = .white
        portTextField.translatesAutoresizingMaskIntoConstraints = false

        // Connect Button
        connectButton = UIButton(type: .system)
        connectButton.setTitle("Connect", for: .normal)
        connectButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        connectButton.backgroundColor = UIColor(red: 0.38, green: 0.78, blue: 0.42, alpha: 1.0)
        connectButton.setTitleColor(.white, for: .normal)
        connectButton.layer.cornerRadius = 10
        connectButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        connectButton.addTarget(self, action: #selector(connectTapped), for: .touchUpInside)

        // Disconnect Button
        disconnectButton = UIButton(type: .system)
        disconnectButton.setTitle("Disconnect", for: .normal)
        disconnectButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        disconnectButton.backgroundColor = .systemRed
        disconnectButton.setTitleColor(.white, for: .normal)
        disconnectButton.layer.cornerRadius = 10
        disconnectButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        disconnectButton.addTarget(self, action: #selector(disconnectTapped), for: .touchUpInside)
        disconnectButton.isHidden = true

        // Image View for MJPEG stream
        imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .black
        imageView.layer.cornerRadius = 16
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.systemGray4.cgColor
        imageView.clipsToBounds = true

        // Status Label
        statusLabel = UILabel()
        statusLabel.text = "Enter Android IP and tap Connect"
        statusLabel.textAlignment = .center
        statusLabel.textColor = .secondaryLabel
        statusLabel.font = .systemFont(ofSize: 16)
        statusLabel.numberOfLines = 0

        // Add to view
        view.addSubview(headerStack)
        view.addSubview(ipTextField)
        view.addSubview(portTextField)
        view.addSubview(connectButton)
        view.addSubview(disconnectButton)
        view.addSubview(imageView)
        view.addSubview(statusLabel)

        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            headerStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            headerStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            ipTextField.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 24),
            ipTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            ipTextField.trailingAnchor.constraint(equalTo: portTextField.leadingAnchor, constant: -12),
            ipTextField.heightAnchor.constraint(equalToConstant: 48),

            portTextField.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 24),
            portTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            portTextField.widthAnchor.constraint(equalToConstant: 80),
            portTextField.heightAnchor.constraint(equalToConstant: 48),

            connectButton.topAnchor.constraint(equalTo: ipTextField.bottomAnchor, constant: 16),
            connectButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            connectButton.widthAnchor.constraint(equalToConstant: 180),

            disconnectButton.topAnchor.constraint(equalTo: ipTextField.bottomAnchor, constant: 16),
            disconnectButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            disconnectButton.widthAnchor.constraint(equalToConstant: 180),

            imageView.topAnchor.constraint(equalTo: connectButton.bottomAnchor, constant: 20),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            imageView.bottomAnchor.constraint(equalTo: statusLabel.topAnchor, constant: -20),

            statusLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }

    private func loadSavedSettings() {
        let defaults = UserDefaults.standard
        ipTextField.text = defaults.string(forKey: "android_ip") ?? ""
        portTextField.text = defaults.string(forKey: "android_port") ?? "8080"
    }

    private func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(ipTextField.text, forKey: "android_ip")
        defaults.set(portTextField.text, forKey: "android_port")
    }

    @objc private func connectTapped() {
        guard let ip = ipTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !ip.isEmpty else {
            showAlert("Please enter Android IP address")
            return
        }
        let port = portTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "8080"

        saveSettings()
        isConnected = true
        connectButton.isHidden = true
        disconnectButton.isHidden = false
        statusLabel.text = "Connecting to \(ip):\(port)..."
        statusLabel.textColor = .systemBlue

        let urlString = "http://\(ip):\(port)/stream"
        guard let url = URL(string: urlString) else {
            showAlert("Invalid IP address")
            return
        }

        // Create URLSession for MJPEG streaming
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        dataTask = session?.dataTask(with: url)
        dataTask?.resume()
    }

    @objc private func disconnectTapped() {
        isConnected = false
        connectButton.isHidden = false
        disconnectButton.isHidden = true
        dataTask?.cancel()
        session?.invalidateAndCancel()
        session = nil
        dataTask = nil
        buffer.removeAll()
        imageView.image = nil
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

        // Find JPEG frames in the MJPEG stream
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