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
        view.backgroundColor = UIColor(red: 0.92, green: 0.94, blue: 0.98, alpha: 1.0)
        setupUI()
        loadSavedSettings()
    }

    private func setupUI() {
        // Use a single container stack view for everything
        let container = UIStackView()
        container.axis = .vertical
        container.alignment = .fill
        container.spacing = 24
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)

        // Header
        let titleLabel = UILabel()
        titleLabel.text = "ScreenCast Receiver"
        titleLabel.font = .systemFont(ofSize: 40, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = UIColor(red: 0.25, green: 0.13, blue: 0.93, alpha: 1.0)

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Receive Android screen on iPad"
        subtitleLabel.font = .systemFont(ofSize: 20)
        subtitleLabel.textAlignment = .center
        subtitleLabel.textColor = .secondaryLabel

        let headerStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        headerStack.axis = .vertical
        headerStack.alignment = .center
        headerStack.spacing = 8

        // IP field + Port field row
        let inputRow = UIStackView()
        inputRow.axis = .horizontal
        inputRow.alignment = .fill
        inputRow.spacing = 16
        inputRow.distribution = .fill

        ipTextField = UITextField()
        ipTextField.placeholder = "Android IP Address (e.g. 192.168.1.50)"
        ipTextField.borderStyle = .roundedRect
        ipTextField.autocapitalizationType = .none
        ipTextField.keyboardType = .numbersAndPunctuation
        ipTextField.backgroundColor = .white
        ipTextField.font = .systemFont(ofSize: 20)
        ipTextField.heightAnchor.constraint(equalToConstant: 56).isActive = true

        portTextField = UITextField()
        portTextField.placeholder = "8080"
        portTextField.borderStyle = .roundedRect
        portTextField.keyboardType = .numberPad
        portTextField.text = "8080"
        portTextField.backgroundColor = .white
        portTextField.font = .systemFont(ofSize: 20)
        portTextField.heightAnchor.constraint(equalToConstant: 56).isActive = true
        portTextField.widthAnchor.constraint(equalToConstant: 140).isActive = true

        inputRow.addArrangedSubview(ipTextField)
        inputRow.addArrangedSubview(portTextField)

        // Buttons row
        let buttonRow = UIStackView()
        buttonRow.axis = .horizontal
        buttonRow.alignment = .fill
        buttonRow.spacing = 16
        buttonRow.distribution = .fillEqually

        connectButton = UIButton(type: .system)
        connectButton.setTitle("Connect", for: .normal)
        connectButton.titleLabel?.font = .systemFont(ofSize: 20, weight: .semibold)
        connectButton.backgroundColor = UIColor(red: 0.38, green: 0.78, blue: 0.42, alpha: 1.0)
        connectButton.setTitleColor(.white, for: .normal)
        connectButton.layer.cornerRadius = 14
        connectButton.heightAnchor.constraint(equalToConstant: 60).isActive = true
        connectButton.addTarget(self, action: #selector(connectTapped), for: .touchUpInside)

        disconnectButton = UIButton(type: .system)
        disconnectButton.setTitle("Disconnect", for: .normal)
        disconnectButton.titleLabel?.font = .systemFont(ofSize: 20, weight: .semibold)
        disconnectButton.backgroundColor = .systemRed
        disconnectButton.setTitleColor(.white, for: .normal)
        disconnectButton.layer.cornerRadius = 14
        disconnectButton.heightAnchor.constraint(equalToConstant: 60).isActive = true
        disconnectButton.addTarget(self, action: #selector(disconnectTapped), for: .touchUpInside)
        disconnectButton.isHidden = true

        buttonRow.addArrangedSubview(connectButton)
        buttonRow.addArrangedSubview(disconnectButton)

        // Image view for MJPEG stream
        imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .black
        imageView.layer.cornerRadius = 16
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.systemGray4.cgColor
        imageView.clipsToBounds = true

        // Status label
        statusLabel = UILabel()
        statusLabel.text = "Enter Android IP and tap Connect"
        statusLabel.textAlignment = .center
        statusLabel.textColor = .secondaryLabel
        statusLabel.font = .systemFont(ofSize: 18)
        statusLabel.numberOfLines = 0

        // Add all to container
        container.addArrangedSubview(headerStack)
        container.addArrangedSubview(inputRow)
        container.addArrangedSubview(buttonRow)
        container.addArrangedSubview(imageView)
        container.addArrangedSubview(statusLabel)

        // Constraints - pin container to safe area with padding
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 60),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -60),
            container.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),

            imageView.heightAnchor.constraint(greaterThanOrEqualToConstant: 300),

            headerStack.heightAnchor.constraint(greaterThanOrEqualToConstant: 80),
            inputRow.heightAnchor.constraint(equalToConstant: 56),
            buttonRow.heightAnchor.constraint(equalToConstant: 60),
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
