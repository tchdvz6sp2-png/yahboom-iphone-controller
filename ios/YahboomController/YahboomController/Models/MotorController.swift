//
//  MotorController.swift
//  YahboomController
//
//  Controls robot motors via UDP commands
//

import Foundation
import Network

class MotorController {
    
    // MARK: - Properties
    private let ipAddress: String
    private let port: Int
    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "com.yahboom.motorcontroller")
    
    var debugMode: Bool = false
    private var lastCommandTime: Date?
    
    // MARK: - Initialization
    
    init(ipAddress: String, port: Int) {
        self.ipAddress = ipAddress
        self.port = port
        setupConnection()
    }
    
    // MARK: - Connection Management
    
    private func setupConnection() {
        let host = NWEndpoint.Host(ipAddress)
        let port = NWEndpoint.Port(integerLiteral: UInt16(self.port))
        
        connection = NWConnection(host: host, port: port, using: .udp)
        
        connection?.stateUpdateHandler = { [weak self] newState in
            if self?.debugMode == true {
                print("Motor controller connection state: \(newState)")
            }
        }
        
        connection?.start(queue: queue)
    }
    
    func testConnection(completion: @escaping (Bool) -> Void) {
        // Send test command
        sendMotorCommand(left: 0, right: 0) { success in
            completion(success)
        }
    }
    
    func disconnect() {
        connection?.cancel()
        connection = nil
        
        if debugMode {
            print("Motor controller disconnected")
        }
    }
    
    // MARK: - Motor Commands
    
    func sendMotorCommand(left: Double, right: Double, completion: ((Bool) -> Void)? = nil) {
        // Clamp values to -100...100
        let leftSpeed = max(-100, min(100, left))
        let rightSpeed = max(-100, min(100, right))
        
        // Create JSON command
        let command: [String: Any] = [
            "left": leftSpeed,
            "right": rightSpeed,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: command) else {
            if debugMode {
                print("Failed to serialize motor command")
            }
            completion?(false)
            return
        }
        
        // Send via UDP
        connection?.send(content: jsonData, completion: .contentProcessed { [weak self] error in
            let success = error == nil
            
            if self?.debugMode == true {
                if success {
                    print("Motor command sent: L=\(leftSpeed), R=\(rightSpeed)")
                } else {
                    print("Failed to send motor command: \(error?.localizedDescription ?? "unknown")")
                }
            }
            
            self?.lastCommandTime = Date()
            completion?(success)
        })
    }
    
    func stop() {
        sendMotorCommand(left: 0, right: 0)
    }
    
    // MARK: - Joystick Control
    
    func setJoystickPosition(x: Double, y: Double) {
        // Convert joystick position (-1...1, -1...1) to motor speeds
        // x: left/right, y: forward/backward
        
        let forward = y * 100  // -100 to 100
        let turn = x * 100     // -100 to 100
        
        // Differential drive calculation
        var leftSpeed = forward + turn
        var rightSpeed = forward - turn
        
        // Normalize if needed
        let maxSpeed = max(abs(leftSpeed), abs(rightSpeed))
        if maxSpeed > 100 {
            leftSpeed = (leftSpeed / maxSpeed) * 100
            rightSpeed = (rightSpeed / maxSpeed) * 100
        }
        
        sendMotorCommand(left: leftSpeed, right: rightSpeed)
    }
}
