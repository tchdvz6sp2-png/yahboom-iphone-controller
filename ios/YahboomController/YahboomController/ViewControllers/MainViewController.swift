//
//  MainViewController.swift
//  YahboomController
//
//  Main controller view with video stream and joystick control
//

import UIKit
import AVFoundation

class MainViewController: UIViewController {
    
    // MARK: - UI Elements
    private let videoPlayerView = VideoPlayerView()
    private let joystickView = JoystickView()
    private let statusLabel = UILabel()
    private let settingsButton = UIBarButtonItem(title: "Settings", style: .plain, target: nil, action: nil)
    
    // MARK: - Properties
    private var yoloDetector = YOLODetector()
    private var connectionManager: ConnectionManager {
        return ConnectionManager.shared
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupConstraints()
        setupConnections()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateConnectionStatus()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        title = "Yahboom Controller"
        view.backgroundColor = .black
        
        // Video player view
        videoPlayerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(videoPlayerView)
        
        // Joystick view
        joystickView.translatesAutoresizingMaskIntoConstraints = false
        joystickView.delegate = self
        view.addSubview(joystickView)
        
        // Status label
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.textColor = .white
        statusLabel.font = .systemFont(ofSize: 14, weight: .medium)
        statusLabel.textAlignment = .center
        statusLabel.text = "Disconnected"
        view.addSubview(statusLabel)
        
        // Settings button
        settingsButton.target = self
        settingsButton.action = #selector(showSettings)
        navigationItem.rightBarButtonItem = settingsButton
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Video player fills most of the screen
            videoPlayerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            videoPlayerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            videoPlayerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            videoPlayerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Joystick in bottom-left corner
            joystickView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            joystickView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            joystickView.widthAnchor.constraint(equalToConstant: 150),
            joystickView.heightAnchor.constraint(equalToConstant: 150),
            
            // Status label at top
            statusLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }
    
    private func setupConnections() {
        connectionManager.onConnectionStatusChanged = { [weak self] isConnected in
            self?.updateConnectionStatus()
        }
    }
    
    // MARK: - Actions
    
    @objc private func showSettings() {
        let settingsVC = SettingsViewController()
        let navController = UINavigationController(rootViewController: settingsVC)
        present(navController, animated: true)
    }
    
    // MARK: - Status Update
    
    private func updateConnectionStatus() {
        if connectionManager.isConnected {
            statusLabel.text = "Connected"
            statusLabel.textColor = .green
            
            // Start video stream if URL is available
            if let rtspURL = connectionManager.getRTSPURL() {
                videoPlayerView.startStream(url: rtspURL)
            }
        } else {
            statusLabel.text = "Disconnected"
            statusLabel.textColor = .red
            videoPlayerView.stopStream()
        }
    }
}

// MARK: - JoystickViewDelegate

extension MainViewController: JoystickViewDelegate {
    func joystickDidMove(x: Double, y: Double) {
        connectionManager.motorController?.setJoystickPosition(x: x, y: y)
    }
    
    func joystickDidRelease() {
        connectionManager.motorController?.stop()
    }
}
