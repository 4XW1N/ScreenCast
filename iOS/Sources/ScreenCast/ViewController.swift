//  ViewController.swift
//  ScreenCast

import UIKit
import WebKit

class ViewController: UIViewController {

    private var webView: WKWebView!
    private var urlTextField: UITextField!
    private var portTextField: UITextField!
    private var connectButton: UIButton!
    private var disconnectButton: UIButton!
    private var statusLabel: UILabel!
    private var settingsButton: UIButton!
    private var isConnected = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "ScreenCast Receiver"

        setupUI()
        loadSavedSettings()
    }

    private func setupUI() {
        let headerLabel = UILabel()
        headerLabel.text = "📱 ScreenCast Receiver"
        headerLabel.font = .systemFont(ofSize: 28, weight: .bold)
        headerLabel.textAlignment = .center
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerLabel)

        urlTextField = UITextField()
        urlTextField.placeholder = "Android IP Address"
        urlTextField.borderStyle = .roundedRect
        urlTextField.autocapitalizationType = .none
        urlTextField.keyboardType = .numbersAndPunctuation
        urlTextField.clearButtonMode = .whileEditing
        urlTextField.translatesAutoresizingMaskIntoConstraints = false

        portTextField = UITextField()
        portTextField.placeholder = "Port (8080)"
        portTextField.borderStyle = .roundedRect
        urlTextField.keyboardType = .numberPad
        portTextField.text = "8080"
        portTextField.translatesAutoresizingMaskIntoConstraints = false

        connectButton = UIButton(type: .system)
        connectButton.setTitle("🔗 Connect", for: .normal)
        connectButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        connectButton.backgroundColor = .systemGreen
        connectButton.setTitleColor(.white, for: .normal)
        connectButton.layer.cornerRadius = 10
        connectButton.addTarget(self, action: #selector(connectStream), for: .touchUpInside)
        connectButton.translatesAutoresizingMaskIntoConstraints = false

        disconnectButton = UIButton(type: .system)
        disconnectButton.setTitle("⏹ Disconnect", for: .normal)
        disconnectButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        disconnectButton.backgroundColor = .systemRed
        disconnectButton.setTitleColor(.white, for: .normal)
        disconnectButton.layer.cornerRadius = 10
        disconnectButton.addTarget(self, action: #selector(disconnectStream), for: .touchUpInside)
        disconnectButton.isHidden = true
        disconnectButton.translatesAutoresizingMaskIntoConstraints = false

        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        webView = WKWebView(frame: .zero, configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.backgroundColor = .black
        webView.layer.cornerRadius = 12
        webView.layer.borderWidth = 2
        webView.layer.borderColor = UIColor.systemGray4.cgColor

        statusLabel = UILabel()
        statusLabel.text = "Enter Android IP and tap Connect"
        statusLabel.textAlignment = .center
        statusLabel.textColor = .secondaryLabel
        statusLabel.font = .systemFont(ofSize: 16)
        statusLabel.numberOfLines = 0
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        settingsButton = UIButton(type: .system)
        settingsButton.setTitle("⚙ Settings", for: .normal)
        settingsButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        settingsButton.setTitleColor(.systemBlue, for: .normal)
        settingsButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
        settingsButton.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(headerLabel)
        view.addSubview(urlTextField)
        view.addSubview(portTextField)
        view.addSubview(connectButton)
        view.addSubview(disconnectButton)
        view.addSubview(webView)
        view.addSubview(statusLabel)
        view.addSubview(settingsButton)

        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            headerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            headerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            urlTextField.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 20),
            urlTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            urlTextField.trailingAnchor.constraint(equalTo: portTextField.leadingAnchor, constant: -12),
            urlTextField.heightAnchor.constraint(equalToConstant: 44),

            portTextField.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 20),
            portTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            portTextField.widthAnchor.constraint(equalToConstant: 80),
            portTextField.heightAnchor.constraint(equalToConstant: 44),

            connectButton.topAnchor.constraint(equalTo: urlTextField.bottomAnchor, constant: 16),
            connectButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            connectButton.trailingAnchor.constraint(equalTo: view.centerXAnchor, constant: -8),
            connectButton.heightAnchor.constraint(equalToConstant: 50),

            disconnectButton.topAnchor.constraint(equalTo: urlTextField.bottomAnchor, constant: 16),
            disconnectButton.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: 8),
            disconnectButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            disconnectButton.heightAnchor.constraint(equalToConstant: 50),

            webView.topAnchor.constraint(equalTo: connectButton.bottomAnchor, constant: 20),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            webView.bottomAnchor.constraint(equalTo: statusLabel.topAnchor, constant: -20),

            statusLabel.bottomAnchor.constraint(equalTo: settingsButton.topAnchor, constant: -12),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            settingsButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
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

        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
        webView.load(request)
    }

    @objc private func disconnectStream() {
        isConnected = false
        connectButton.isHidden = false
        disconnectButton.isHidden = true
        webView.loadHTMLString("<html><body style='background:black;color:white;text-align:center;padding-top:40%'><h2>Disconnected</h2><p>Tap Connect to start casting</p></body></html>", baseURL: nil)
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