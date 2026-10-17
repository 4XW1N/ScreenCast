//  ViewController.swift
//  ScreenCast

import UIKit

class ViewController: UIViewController {

    private var imageView: UIImageView!
    private var ipTextField: UITextField!
    private var connectButton: UIButton!
    private var statusLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0)
        setupUI()
    }

    private func setupUI() {
        // Header
        let headerLabel = UILabel()
        headerLabel.text = "📱 ScreenCast Receiver"
        headerLabel.font = .systemFont(ofSize: isPad() ? 36 : 28, weight: .bold)
        headerLabel.textAlignment = .center
        headerLabel.textColor = UIColor(red: 0.25, green: 0.13, blue: 0.93, alpha: 1.0)
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerLabel)

        // IP Text Field
        ipTextField = UITextField()
        ipTextField.placeholder = "Android IP (e.g., 192.168.1.50)"
        ipTextField.borderStyle = .roundedRect
        ipTextField.autocapitalizationType = .none
        ipTextField.keyboardType = .numbersAndPunctuation
        ipTextField.clearButtonMode = .whileEditing
        ipTextField.translatesAutoresizingMaskIntoConstraints = false
        ipTextField.layer.cornerRadius = 10
        ipTextField.layer.borderWidth = 1
        ipTextField.layer.borderColor = UIColor.systemGray4.cgColor
        ipTextField.backgroundColor = .white
        view.addSubview(ipTextField)

        // Connect Button
        connectButton = UIButton(type: .system)
        connectButton.setTitle("🔗 Connect", for: .normal)
        connectButton.titleLabel?.font = .systemFont(ofSize: isPad() ? 20 : 18, weight: .semibold)
        connectButton.backgroundColor = UIColor(red: 0.38, green: 0.78, blue: 0.42, alpha: 1.0)
        connectButton.setTitleColor(.white, for: .normal)
        connectButton.layer.cornerRadius = 12
        connectButton.translatesAutoresizingMaskIntoConstraints = false
        connectButton.addTarget(self, action: #selector(connectTapped), for: .touchUpInside)
        view.addSubview(connectButton)

        // Image View for MJPEG stream
        imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .black
        imageView.layer.cornerRadius = 16
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.systemGray4.cgColor
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)

        // Status Label
        statusLabel = UILabel()
        statusLabel.text = "Enter Android IP and tap Connect"
        statusLabel.textAlignment = .center
        statusLabel.textColor = .secondaryLabel
        statusLabel.font = .systemFont(ofSize: isPad() ? 18 : 16)
        statusLabel.numberOfLines = 0
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)

        // Settings Button
        let settingsButton = UIButton(type: .system)
        settingsButton.setTitle("⚙ Settings", for: .normal)
        settingsButton.titleLabel?.font = .systemFont(ofSize: isPad() ? 16 : 14, weight: .medium)
        settingsButton.setTitleColor(.systemBlue, for: .normal)
        settingsButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(settingsButton)

        // Layout constraints
        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: isPad() ? 40 : 20),
            headerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            headerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            ipTextField.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: isPad() ? 30 : 20),
            ipTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: isPad() ? 60 : 40),
            ipTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: isPad() ? -60 : -40),
            ipTextField.heightAnchor.constraint(equalToConstant: isPad() ? 50 : 44),

            connectButton.topAnchor.constraint(equalTo: ipTextField.bottomAnchor, constant: 16),
            connectButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            connectButton.widthAnchor.constraint(equalToConstant: isPad() ? 180 : 150),
            connectButton.heightAnchor.constraint(equalToConstant: isPad() ? 56 : 50),

            imageView.topAnchor.constraint(equalTo: connectButton.bottomAnchor, constant: isPad() ? 30 : 20),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            imageView.bottomAnchor.constraint(equalTo: statusLabel.topAnchor, constant: -20),

            statusLabel.bottomAnchor.constraint(equalTo: settingsButton.topAnchor, constant: -12),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            settingsButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: isPad() ? -30 : -20),
            settingsButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    private func isPad() -> Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }

    @objc private func connectTapped() {
        guard let ip = ipTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !ip.isEmpty else {
            showAlert("Please enter Android IP address")
            return
        }

        statusLabel.text = "Connecting to Android..."
        statusLabel.textColor = .systemBlue

        let urlString = "http://\(ip):8080/stream"
        guard let url = URL(string: urlString) else {
            showAlert("Invalid IP address")
            return
        }

        // Use URLSession to fetch MJPEG stream
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        let task = session.dataTask(with: url)
        task.resume()
    }

    @objc private func openSettings() {
        let alert = UIAlertController(title: "Settings", message: "Configure casting options", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
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