//
//  ConnectionViewModel.swift
//  YahboomController
//
//  View model for managing robot connection state
//

import Foundation
import Combine

/// View model for connection management
class ConnectionViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var connectionState: ConnectionState = .disconnected
    @Published var isConnecting = false
    
    // MARK: - Properties
    
    private let sshManager = SSHManager()
    private let settings: RobotSettings
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(settings: RobotSettings) {
        self.settings = settings
        
        // Observe SSH connection state
        sshManager.$connectionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.connectionState = state
                self?.isConnecting = (state == .connecting)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Connection Control
    
    /// Connect to the robot
    func connect() {
        guard !connectionState.isConnected else {
            print("[Connection] Already connected")
            return
        }
        
        // Get password from keychain
        guard let password = KeychainManager.get(key: "ssh_password") else {
            print("[Connection] No saved password. Please enter password in Settings.")
            connectionState = .error("No password saved")
            return
        }
        
        sshManager.connect(
            host: settings.robotIP,
            port: settings.sshPort,
            username: settings.sshUsername,
            password: password
        )
    }
    
    /// Disconnect from the robot
    func disconnect() {
        sshManager.disconnect()
    }
    
    /// Toggle connection state
    func toggleConnection() {
        if connectionState.isConnected {
            disconnect()
        } else {
            connect()
        }
    }
}
