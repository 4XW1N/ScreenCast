//  ViewController.swift
//  ScreenCast

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        let label = UILabel()
        label.text = "ScreenCast Receiver"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        let ipField = UITextField()
        ipField.placeholder = "Android IP"
        ipField.borderStyle = .roundedRect
        ipField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(ipField)
        
        let button = UIButton(type: .system)
        button.setTitle("Connect", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            ipField.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 30),
            ipField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            ipField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            ipField.heightAnchor.constraint(equalToConstant: 44),
            
            button.topAnchor.constraint(equalTo: ipField.bottomAnchor, constant: 20),
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.widthAnchor.constraint(equalToConstant: 150),
            button.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        button.addTarget(self, action: #selector(connectTapped), for: .touchUpInside)
    }
    
    @objc private func connectTapped() {
        let alert = UIAlertController(title: "ScreenCast", message: "Connect to Android device", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}