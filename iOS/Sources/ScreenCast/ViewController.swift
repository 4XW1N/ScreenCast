//  ViewController.swift
//  ScreenCast

import UIKit

class ViewController: UIViewController, URLSessionDataDelegate {

    private var imageView: UIImageView!
    private var ipTextField: UITextField!
    private var connectButton: UIButton!
    private var statusLabel: UILabel!
    private var settingsButton: UIButton!

    private var session: URLSession?
    private var dataTask: URLSessionDataTask?
    private var isConnected = false
    private var buffer = Data()
    private var portTextField: UITextField!
    private var disconnectButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0)
        setupUI()
        loadSavedSettings()
    }

    private func setupUI() {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])

        let titleLabel = UILabel()
        titleLabel.text = "ScreenCast Receiver"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = UIColor(red: 0.25, green: 0.13, blue: 0.93, alpha: 1.0)

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Receive Android screen on iPad"
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textAlignment = .center
        subtitleLabel.textColor = .secondaryLabel

        ipTextField = UITextField()
        ipTextField.placeholder = "Android IP Address"
        ipTextField.borderStyle = .roundedRect
        ipTextField.autocapitalizationType = .none
        ipTextField.keyboardType = .numbersAndPunctuation
        ipTextField.backgroundColor = .white

        portTextField = UITextField()
        portTextField.placeholder = "8080"
        portTextField.borderStyle = .roundedRect
        portTextField.keyboardType = .numberPad
        portTextField.text = "8080"
        portTextField.backgroundColor = .white

        connectButton = UIButton(type: .system)
        connectButton.setTitle("Connect", for: .normal)
        connectButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        connectButton.backgroundColor = UIColor(red: 0.38, green: 0.78, blue: 0.42, alpha: 1.0)
        connectButton.setTitleColor(.white, for: .normal)
        connectButton.layer.cornerRadius = 10
        connectButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        connectButton.addTarget(self, action: #selector(connectTapped), for: .touchUpInside)

        disconnectButton = UIButton(type: .system)
        disconnectButton.setTitle("Disconnect", for: .normal)
        disconnectButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        disconnectButton.backgroundColor = .systemRed
        disconnectButton.setTitleColor(.white, for: .normal)
        disconnectButton.layer.cornerRadius = 10
        disconnectButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        disconnectButton.addTarget(self, action: #selector(disconnectTapped), for: .touchUpInside)
        disconnectButton.isHidden = true

        imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .black
        imageView.layer.cornerRadius = 16
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.systemGray4.cgColor
        imageView.clipsToBounds = true

        statusLabel = UILabel()
        statusLabel.text = "Enter Android IP and tap Connect"
        statusLabel.textAlignment = .center
        statusLabel.textColor = .secondaryLabel
        statusLabel.font = .systemFont(ofSize: 16)
        statusLabel.numberOfLines = 0

        settingsButton = UIButton(type: .system)
        settingsButton.setTitle("Settings", for: .normal)
        settingsButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        settingsButton.setTitleColor(.systemBlue, for: .normal)
        settingsButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)

        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(subtitleLabel)
        stackView.addArrangedSubview(ipTextField)
        stackView.addArrangedSubview(portTextField)
        stackView.addArrangedSubview(connectButton)
        stackView.addArrangedSubview(disconnectButton)
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(statusLabel)
        stackView.addArrangedSubview(settingsButton)

        imageView.heightAnchor.constraint(greaterThanOrEqualToConstant: 300).isActive = true
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
        let urlString = "http://\(ip):\(port)/stream"
        guard let url = URL(string: urlString) else {
            showAlert("Invalid IP address")
            return
        }

        saveSettings()
        isConnected = true
        connectButton.isHidden = true
        disconnectButton.isHidden = false
        statusLabel.text = "Connecting to Android..."
        statusLabel.textColor = .systemBlue

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

    // MARK: - URLSessionDataDelegate
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