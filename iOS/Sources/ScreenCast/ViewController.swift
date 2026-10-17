//  ViewController.swift
//  ScreenCast

import UIKit

class ViewController: UIViewController {

    private var imageView: UIImageView!
    private var urlTextField: UITextField!
    private var portTextField: UITextField!
    private var connectButton: UIButton!
    private var disconnectButton: UIButton!
    private var statusLabel: UILabel!
    private var settingsButton: UIButton!

    private var session: URLSession?
    private var dataTask: URLSessionDataTask?
    private var isConnected = false
    private var buffer = Data()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "ScreenCast Receiver"
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
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = .secondaryLabel

        headerStack.addArrangedSubview(iconLabel)
        headerStack.addArrangedSubview(titleLabel)
        headerStack.addArrangedSubview(subtitleLabel)
        view.addSubview(headerStack)

        // IP Text Field
        urlTextField = UITextField()
        urlTextField.placeholder = "Android IP Address"
        urlTextField.borderStyle = .roundedRect
        urlTextField.autocapitalizationType = .none
        urlTextField.keyboardType = .numbersAndPunctuation
        urlTextField.clearButtonMode = .whileEditing
        urlTextField.translatesAutoresizingMaskIntoConstraints = false
        urlTextField.layer.cornerRadius = 10
        urlTextField.layer.borderWidth = 1
        urlTextField.layer.borderColor = UIColor.systemGray4.cgColor

        // Port Input
        portTextField = UITextField()
        portTextField.placeholder = "8080"
        portTextField.borderStyle = .roundedRect
        portTextField.keyboardType = .numberPad
        portTextField.text = "8080"
        portTextField.translatesAutoresizingMaskIntoConstraints = false
        portTextField.layer.cornerRadius = 10
        portTextField.layer.borderWidth = 1
        portTextField.layer.borderColor = UIColor.systemGray4.cgColor

        // Connect Button
        connectButton = UIButton(type: .system)
        connectButton.setTitle("🔗 Connect", for: .normal)
        connectButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        connectButton.backgroundColor = .systemGreen
        connectButton.setTitleColor(.white, for: .normal)
        connectButton.layer.cornerRadius = 12
        connectButton.addTarget(self, action: #selector(connectStream), for: .touchUpInside)
        connectButton.translatesAutoresizingMaskIntoConstraints = false

        // Disconnect Button
        disconnectButton = UIButton(type: .system)
        disconnectButton.setTitle("⏹ Disconnect", for: .normal)
        disconnectButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        disconnectButton.backgroundColor = .systemRed
        disconnectButton.setTitleColor(.white, for: .normal)
        disconnectButton.layer.cornerRadius = 12
        disconnectButton.addTarget(self, action: #selector(disconnectStream), for: .touchUpInside)
        disconnectButton.isHidden = true
        disconnectButton.translatesAutoresizingMaskIntoConstraints = false

        // Image View for MJPEG stream
        imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .black
        imageView.layer.cornerRadius = 16
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.systemGray4.cgColor
        imageView.translatesAutoresizingMaskIntoConstraints = false

        // Status Label
        statusLabel = UILabel()
        statusLabel.text = "Enter Android IP and tap Connect"
        statusLabel.textAlignment = .center
        statusLabel.textColor = .secondaryLabel
        statusLabel.font = .systemFont(ofSize: 16)
        statusLabel.numberOfLines = 0
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        // Settings Button
        settingsButton = UIButton(type: .system)
        settingsButton.setTitle("⚙ Settings", for: .normal)
        settingsButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        settingsButton.setTitleColor(.systemBlue, for: .normal)
        settingsButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
        settingsButton.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(headerStack)
        view.addSubview(urlTextField)
        view.addSubview(portTextField)
        view.addSubview(connectButton)
        view.addSubview(disconnectButton)
        view.addSubview(imageView)
        view.addSubview(statusLabel)
        view.addSubview(settingsButton)

        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            headerStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            headerStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            urlTextField.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 24),
            urlTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            urlTextField.trailingAnchor.constraint(equalTo: portTextField.leadingAnchor, constant: -12),
            urlTextField.heightAnchor.constraint(equalToConstant: 48),

            portTextField.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 24),
            portTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            portTextField.widthAnchor.constraint(equalToConstant: 80),
            portTextField.heightAnchor.constraint(equalToConstant: 48),

            connectButton.topAnchor.constraint(equalTo: urlTextField.bottomAnchor, constant: 16),
            connectButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            connectButton.trailingAnchor.constraint(equalTo: view.centerXAnchor, constant: -8),
            connectButton.heightAnchor.constraint(equalToConstant: 52),

            disconnectButton.topAnchor.constraint(equalTo: urlTextField.bottomAnchor, constant: 16),
            disconnectButton.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: 8),
            disconnectButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            disconnectButton.heightAnchor.constraint(equalToConstant: 52),

            imageView.topAnchor.constraint(equalTo: connectButton.bottomAnchor, constant: 20),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            imageView.bottomAnchor.constraint(equalTo: statusLabel.topAnchor, constant: -20),

            statusLabel.bottomAnchor.constraint(equalTo: settingsButton.topAnchor, constant: -12),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            settingsButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            settingsButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    private func loadSavedSettings() {
        let defaults = UserDefaults.standard
        urlTextField.text = defaults.string(forKey: "android_ip") ?? ""
        portTextField.text = defaults.string(forKey: "android_port") ?? "8080"
    }

    private func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(urlTextField.text, forKey: "android_ip")
        defaults.set(portTextField.text, forKey: "android_port")
    }

    @objc private func connectStream() {
        guard let ip = urlTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !ip.isEmpty else {
            showAlert("Please enter Android IP address")
            return
        }
        let port = portTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "8080"
        let urlString = "http://\(ip):\(port)/stream"
        guard let url = URL(string: urlString) else {
            showAlert("Invalid IP address")
            return
        }

        saveSettings()
        isConnected = true
        connectButton.isHidden = true
        disconnectButton.isHidden = false
        statusLabel.text = "🔄 Connecting to Android..."
        statusLabel.textColor = .systemBlue

        // Use URLSession to fetch MJPEG stream
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        dataTask = session?.dataTask(with: url)
        dataTask?.resume()
    }

    @objc private func disconnectStream() {
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

    @objc private func openSettings() {
        let alert = UIAlertController(title: "Settings", message: "Configure casting options", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
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
        while let range = buffer.range(of: Data([0xFF, 0xD8, 0xFF])) {
            // Found start of JPEG
            let start = range.lowerBound
            if let endRange = buffer.range(of: Data([0xFF, 0xD9]), in: start..<buffer.count) {
                let end = endRange.upperBound
                let jpegData = buffer.subdata(in: start..<end)
                buffer.removeSubrange(0..<end)

                if let image = UIImage(data: jpegData) {
                    DispatchQueue.main.async {
                        self.imageView.image = image
                        if self.statusLabel.text != "🟢 Connected - Streaming" {
                            self.statusLabel.text = "🟢 Connected - Streaming"
                            self.statusLabel.textColor = .systemGreen
                        }
                    }
                }
            } else {
                break
            }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        DispatchQueue.main.async {
            if let error = error {
                self.statusLabel.text = "❌ Error: \(error.localizedDescription)"
                self.statusLabel.textColor = .systemRed
            }
        }
    }
}