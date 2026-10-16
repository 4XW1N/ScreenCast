//  ViewController.swift
//  ScreenCast

import UIKit
import WebKit

class ViewController: UIViewController {

    private var webView: WKWebView!
    private var urlTextField: UITextField!
    private var loadButton: UIButton!
    private var statusLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "ScreenCast Receiver"

        setupUI()
        loadSavedSettings()
    }

    private func setupUI() {
        // IP Text Field
        urlTextField = UITextField()
        urlTextField.placeholder = "Android IP (e.g., 192.168.1.50)"
        urlTextField.borderStyle = .roundedRect
        urlTextField.autocapitalizationType = .none
        urlTextField.keyboardType = .numbersAndPunctuation
        urlTextField.clearButtonMode = .whileEditing
        urlTextField.translatesAutoresizingMaskIntoConstraints = false

        // Load Button
        loadButton = UIButton(type: .system)
        loadButton.setTitle("Connect", for: .normal)
        loadButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        loadButton.backgroundColor = .systemBlue
        loadButton.setTitleColor(.white, for: .normal)
        loadButton.layer.cornerRadius = 8
        loadButton.addTarget(self, action: #selector(loadStream), for: .touchUpInside)
        loadButton.translatesAutoresizingMaskIntoConstraints = false

        // Web View
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        webView = WKWebView(frame: .zero, configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.backgroundColor = .black
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false

        // Status Label
        statusLabel = UILabel()
        statusLabel.text = "Enter Android IP and tap Connect"
        statusLabel.textAlignment = .center
        statusLabel.textColor = .secondaryLabel
        statusLabel.font = .systemFont(ofSize: 16)
        statusLabel.numberOfLines = 0
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(urlTextField)
        view.addSubview(loadButton)
        view.addSubview(webView)
        view.addSubview(statusLabel)

        NSLayoutConstraint.activate([
            urlTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            urlTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            urlTextField.trailingAnchor.constraint(equalTo: loadButton.leadingAnchor, constant: -12),
            urlTextField.heightAnchor.constraint(equalToConstant: 44),

            loadButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            loadButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            loadButton.widthAnchor.constraint(equalToConstant: 100),
            loadButton.heightAnchor.constraint(equalToConstant: 44),

            webView.topAnchor.constraint(equalTo: urlTextField.bottomAnchor, constant: 16),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: statusLabel.topAnchor, constant: -16),

            statusLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }

    private func loadSavedSettings() {
        let defaults = UserDefaults.standard
        urlTextField.text = defaults.string(forKey: "android_ip") ?? ""
    }

    private func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(urlTextField.text, forKey: "android_ip")
    }

    @objc private func loadStream() {
        guard let ip = urlTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !ip.isEmpty else {
            showAlert("Please enter Android IP address")
            return
        }

        let urlString = "http://\(ip):8080/stream"
        guard let url = URL(string: urlString) else {
            showAlert("Invalid IP address")
            return
        }

        saveSettings()
        statusLabel.text = "Connecting to Android..."
        statusLabel.textColor = .secondaryLabel

        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
        webView.load(request)
    }

    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: "ScreenCast", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}