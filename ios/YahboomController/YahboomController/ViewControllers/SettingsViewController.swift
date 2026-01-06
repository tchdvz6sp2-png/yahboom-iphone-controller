//
//  SettingsViewController.swift
//  YahboomController
//
//  Settings and configuration view controller
//

import UIKit

class SettingsViewController: UIViewController {
    
    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let ipAddressField = UITextField()
    private let motorPortField = UITextField()
    private let rtspURLField = UITextField()
    private let connectButton = UIButton(type: .system)
    private let disconnectButton = UIButton(type: .system)
    private let statusLabel = UILabel()
    
    // MARK: - Properties
    private var connectionManager: ConnectionManager {
        return ConnectionManager.shared
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupConstraints()
        loadSettings()
        updateUI()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        title = "Settings"
        view.backgroundColor = .systemBackground
        
        // Close button
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Close", 
                                                            style: .plain, 
                                                            target: self, 
                                                            action: #selector(closeSettings))
        
        // Scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // IP Address field
        setupTextField(ipAddressField, placeholder: "Raspberry Pi IP (e.g., 192.168.1.100)")
        ipAddressField.keyboardType = .decimalPad
        
        // Motor port field
        setupTextField(motorPortField, placeholder: "Motor Control Port (default: 5005)")
        motorPortField.keyboardType = .numberPad
        
        // RTSP URL field
        setupTextField(rtspURLField, placeholder: "RTSP URL (e.g., rtsp://192.168.1.100:8554/stream)")
        rtspURLField.keyboardType = .URL
        
        // Connect button
        connectButton.translatesAutoresizingMaskIntoConstraints = false
        connectButton.setTitle("Connect", for: .normal)
        connectButton.backgroundColor = .systemBlue
        connectButton.setTitleColor(.white, for: .normal)
        connectButton.layer.cornerRadius = 8
        connectButton.addTarget(self, action: #selector(connectTapped), for: .touchUpInside)
        contentView.addSubview(connectButton)
        
        // Disconnect button
        disconnectButton.translatesAutoresizingMaskIntoConstraints = false
        disconnectButton.setTitle("Disconnect", for: .normal)
        disconnectButton.backgroundColor = .systemRed
        disconnectButton.setTitleColor(.white, for: .normal)
        disconnectButton.layer.cornerRadius = 8
        disconnectButton.addTarget(self, action: #selector(disconnectTapped), for: .touchUpInside)
        contentView.addSubview(disconnectButton)
        
        // Status label
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.font = .systemFont(ofSize: 16, weight: .medium)
        contentView.addSubview(statusLabel)
    }
    
    private func setupTextField(_ textField: UITextField, placeholder: String) {
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = placeholder
        textField.borderStyle = .roundedRect
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        contentView.addSubview(textField)
    }
    
    private func setupConstraints() {
        let guide = view.safeAreaLayoutGuide
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: guide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            ipAddressField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            ipAddressField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            ipAddressField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            ipAddressField.heightAnchor.constraint(equalToConstant: 44),
            
            motorPortField.topAnchor.constraint(equalTo: ipAddressField.bottomAnchor, constant: 12),
            motorPortField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            motorPortField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            motorPortField.heightAnchor.constraint(equalToConstant: 44),
            
            rtspURLField.topAnchor.constraint(equalTo: motorPortField.bottomAnchor, constant: 12),
            rtspURLField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            rtspURLField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            rtspURLField.heightAnchor.constraint(equalToConstant: 44),
            
            connectButton.topAnchor.constraint(equalTo: rtspURLField.bottomAnchor, constant: 24),
            connectButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            connectButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            connectButton.heightAnchor.constraint(equalToConstant: 50),
            
            disconnectButton.topAnchor.constraint(equalTo: connectButton.bottomAnchor, constant: 12),
            disconnectButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            disconnectButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            disconnectButton.heightAnchor.constraint(equalToConstant: 50),
            
            statusLabel.topAnchor.constraint(equalTo: disconnectButton.bottomAnchor, constant: 24),
            statusLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            statusLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
        ])
    }
    
    // MARK: - Actions
    
    @objc private func closeSettings() {
        dismiss(animated: true)
    }
    
    @objc private func connectTapped() {
        guard let ipAddress = ipAddressField.text, !ipAddress.isEmpty else {
            showAlert(message: "Please enter Raspberry Pi IP address")
            return
        }
        
        let motorPort = Int(motorPortField.text ?? "") ?? 5005
        let rtspURL = rtspURLField.text ?? "rtsp://\(ipAddress):8554/stream"
        
        // Save settings
        connectionManager.saveSettings(ipAddress: ipAddress, motorPort: motorPort, rtspURL: rtspURL)
        
        // Connect
        statusLabel.text = "Connecting..."
        statusLabel.textColor = .systemOrange
        
        connectionManager.connect(to: ipAddress, motorPort: motorPort) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.updateUI()
                
                if success {
                    self?.showAlert(message: "Connected successfully!")
                } else {
                    self?.showAlert(message: "Connection failed: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
    
    @objc private func disconnectTapped() {
        connectionManager.disconnectAll()
        updateUI()
    }
    
    // MARK: - Helpers
    
    private func loadSettings() {
        ipAddressField.text = connectionManager.piIPAddress
        motorPortField.text = "\(connectionManager.getMotorPort())"
        rtspURLField.text = connectionManager.getRTSPURL()
    }
    
    private func updateUI() {
        if connectionManager.isConnected {
            statusLabel.text = "✓ Connected"
            statusLabel.textColor = .systemGreen
            connectButton.isEnabled = false
            disconnectButton.isEnabled = true
        } else {
            statusLabel.text = "Not Connected"
            statusLabel.textColor = .systemRed
            connectButton.isEnabled = true
            disconnectButton.isEnabled = false
        }
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
