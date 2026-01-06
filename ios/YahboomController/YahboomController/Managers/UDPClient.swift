//
//  UDPClient.swift
//  YahboomController
//
//  UDP client for sending motor commands to the robot
//

import Foundation
import Network

/// UDP client for motor command transmission
class UDPClient {
    
    // MARK: - Properties
    
    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "com.yahboom.udp")
    
    var isConnected: Bool {
        return connection?.state == .ready
    }
    
    // MARK: - Connection
    
    /// Connect to the robot's motor controller
    /// - Parameters:
    ///   - host: Robot IP address
    ///   - port: UDP port
    func connect(host: String, port: Int) {
        // Create endpoint
        guard let portNW = NWEndpoint.Port(rawValue: UInt16(port)) else {
            print("[UDP] Invalid port: \(port)")
            return
        }
        
        let endpoint = NWEndpoint.hostPort(
            host: NWEndpoint.Host(host),
            port: portNW
        )
        
        // Create UDP connection
        connection = NWConnection(to: endpoint, using: .udp)
        
        // Setup state handler
        connection?.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                print("[UDP] Connected to \(host):\(port)")
            case .failed(let error):
                print("[UDP] Connection failed: \(error)")
                self?.connection = nil
            case .waiting(let error):
                print("[UDP] Connection waiting: \(error)")
            default:
                break
            }
        }
        
        // Start connection
        connection?.start(queue: queue)
    }
    
    /// Disconnect from the robot
    func disconnect() {
        connection?.cancel()
        connection = nil
        print("[UDP] Disconnected")
    }
    
    // MARK: - Sending Commands
    
    /// Send a motor command to the robot
    /// - Parameter command: Motor command to send
    func send(command: MotorCommand) {
        guard let data = command.toData() else {
            print("[UDP] Failed to encode command")
            return
        }
        
        send(data: data)
    }
    
    /// Send raw data via UDP
    /// - Parameter data: Data to send
    private func send(data: Data) {
        guard let connection = connection else {
            print("[UDP] Not connected")
            return
        }
        
        connection.send(content: data, completion: .contentProcessed { error in
            if let error = error {
                print("[UDP] Send error: \(error)")
            }
        })
    }
    
    // MARK: - Cleanup
    
    deinit {
        disconnect()
    }
}
