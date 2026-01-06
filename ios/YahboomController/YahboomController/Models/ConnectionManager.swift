//
//  ConnectionManager.swift
//  YahboomController
//
//  Manages all network connections to the Raspberry Pi
//

import Foundation
import Network

class ConnectionManager {
    
    // MARK: - Singleton
    static let shared = ConnectionManager()
    
    // MARK: - Properties
    var motorController: MotorController?
    var sshManager: SSHManager?
    
    private(set) var isConnected: Bool = false
    private(set) var piIPAddress: String?
    
    var debugMode: Bool = false {
        didSet {
            print("Debug mode: \(debugMode ? "enabled" : "disabled")")
        }
    }
    
    // Connection status callback
    var onConnectionStatusChanged: ((Bool) -> Void)?
    
    // MARK: - Initialization
    private init() {
        loadSettings()
    }
    
    // MARK: - Public Methods
    
    func connect(to ipAddress: String, motorPort: Int, completion: @escaping (Bool, Error?) -> Void) {
        piIPAddress = ipAddress
        
        // Initialize motor controller
        motorController = MotorController(ipAddress: ipAddress, port: motorPort)
        motorController?.debugMode = debugMode
        
        // Test connection
        motorController?.testConnection { [weak self] success in
            DispatchQueue.main.async {
                self?.isConnected = success
                self?.onConnectionStatusChanged?(success)
                completion(success, success ? nil : NSError(domain: "ConnectionManager", 
                                                           code: -1, 
                                                           userInfo: [NSLocalizedDescriptionKey: "Failed to connect"]))
            }
        }
    }
    
    func disconnectAll() {
        motorController?.disconnect()
        motorController = nil
        sshManager?.disconnect()
        sshManager = nil
        isConnected = false
        onConnectionStatusChanged?(false)
        
        if debugMode {
            print("All connections disconnected")
        }
    }
    
    func saveSettings(ipAddress: String, motorPort: Int, rtspURL: String) {
        UserDefaults.standard.set(ipAddress, forKey: "pi_ip_address")
        UserDefaults.standard.set(motorPort, forKey: "motor_port")
        UserDefaults.standard.set(rtspURL, forKey: "rtsp_url")
        
        if debugMode {
            print("Settings saved: IP=\(ipAddress), Port=\(motorPort)")
        }
    }
    
    func loadSettings() {
        piIPAddress = UserDefaults.standard.string(forKey: "pi_ip_address")
        
        if debugMode {
            print("Settings loaded: IP=\(piIPAddress ?? "none")")
        }
    }
    
    func getMotorPort() -> Int {
        return UserDefaults.standard.integer(forKey: "motor_port") != 0 
            ? UserDefaults.standard.integer(forKey: "motor_port") 
            : 5005
    }
    
    func getRTSPURL() -> String? {
        return UserDefaults.standard.string(forKey: "rtsp_url")
    }
}
