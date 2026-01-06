//
//  SSHManager.swift
//  YahboomController
//
//  SSH connection manager for robot communication
//
//  Note: This is a simplified implementation. For production use,
//  consider using a library like NMSSH or implementing proper SSH protocol.
//

import Foundation
import Network

/// Connection state
enum ConnectionState {
    case disconnected
    case connecting
    case connected
    case error(String)
    
    var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }
}

/// Simple SSH-like connection manager
/// In production, replace with proper SSH library (e.g., NMSSH)
class SSHManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var connectionState: ConnectionState = .disconnected
    
    // MARK: - Properties
    
    private var keepAliveTimer: Timer?
    private let queue = DispatchQueue(label: "com.yahboom.ssh")
    
    // MARK: - Connection
    
    /// Connect to robot via SSH
    /// - Parameters:
    ///   - host: Robot IP address
    ///   - port: SSH port
    ///   - username: SSH username
    ///   - password: SSH password
    func connect(host: String, port: Int, username: String, password: String) {
        DispatchQueue.main.async {
            self.connectionState = .connecting
        }
        
        print("[SSH] Connecting to \(username)@\(host):\(port)")
        
        // For MVP, we'll simulate a connection check via TCP
        // In production, use a proper SSH library
        queue.async { [weak self] in
            self?.performConnection(host: host, port: port, username: username, password: password)
        }
    }
    
    private func performConnection(host: String, port: Int, username: String, password: String) {
        // Create a TCP connection to verify host is reachable
        guard let portNW = NWEndpoint.Port(rawValue: UInt16(port)) else {
            DispatchQueue.main.async {
                self.connectionState = .error("Invalid port")
            }
            return
        }
        
        let endpoint = NWEndpoint.hostPort(
            host: NWEndpoint.Host(host),
            port: portNW
        )
        
        let connection = NWConnection(to: endpoint, using: .tcp)
        
        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                print("[SSH] Connection established")
                
                // Save credentials securely
                KeychainManager.save(password: password, for: "ssh_password")
                
                DispatchQueue.main.async {
                    self?.connectionState = .connected
                    self?.startKeepAlive()
                }
                
                // Close this test connection
                connection.cancel()
                
            case .failed(let error):
                print("[SSH] Connection failed: \(error)")
                DispatchQueue.main.async {
                    self?.connectionState = .error(error.localizedDescription)
                }
                
            case .waiting(let error):
                print("[SSH] Connection waiting: \(error)")
                
            default:
                break
            }
        }
        
        connection.start(queue: queue)
        
        // Timeout after 10 seconds
        DispatchQueue.global().asyncAfter(deadline: .now() + 10) {
            if case .connecting = self.connectionState {
                connection.cancel()
                DispatchQueue.main.async {
                    self.connectionState = .error("Connection timeout")
                }
            }
        }
    }
    
    /// Disconnect from robot
    func disconnect() {
        print("[SSH] Disconnecting")
        
        stopKeepAlive()
        
        DispatchQueue.main.async {
            self.connectionState = .disconnected
        }
    }
    
    // MARK: - Keep Alive
    
    private func startKeepAlive() {
        // Send periodic keep-alive to maintain connection
        keepAliveTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.sendKeepAlive()
        }
    }
    
    private func stopKeepAlive() {
        keepAliveTimer?.invalidate()
        keepAliveTimer = nil
    }
    
    private func sendKeepAlive() {
        // In a real implementation, send SSH keep-alive packet
        print("[SSH] Keep-alive sent")
    }
    
    // MARK: - Cleanup
    
    deinit {
        disconnect()
    }
}
