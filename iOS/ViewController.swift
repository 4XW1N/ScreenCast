//  ViewController.swift
//  ScreenCast

import UIKit

class ViewController: UIViewController {

    private let statusLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "ScreenCast Receiver"

        statusLabel.text = "Ready to receive"
        statusLabel.textAlignment = .center
        statusLabel.textColor = .secondaryLabel
        statusLabel.font = .systemFont(ofSize: 16)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(statusLabel)
        NSLayoutConstraint.activate([
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}