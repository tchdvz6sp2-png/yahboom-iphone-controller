//
//  SSHManager.swift
//  YahboomController
//
//  Manages SSH connections to Raspberry Pi for remote commands
//

import Foundation

class SSHManager {
    
    // MARK: - Properties
    private var host: String?
    private var username: String?
    private var password: String?
    private var isConnected: Bool = false
    
    // MARK: - Initialization
    
    init() {
        loadCredentials()
    }
    
    // MARK: - Connection Management
    
    func connect(host: String, username: String, password: String, completion: @escaping (Bool, Error?) -> Void) {
        self.host = host
        self.username = username
        self.password = password
        
        // Note: iOS does not have built-in SSH support
        // In a real implementation, you would use a library like NMSSH or implement your own
        // For now, this is a placeholder that saves credentials
        
        saveCredentials()
        isConnected = true
        completion(true, nil)
    }
    
    func disconnect() {
        isConnected = false
        print("SSH disconnected")
    }
    
    // MARK: - Command Execution
    
    func executeCommand(_ command: String, completion: @escaping (String?, Error?) -> Void) {
        guard isConnected else {
            completion(nil, NSError(domain: "SSHManager", 
                                   code: -1, 
                                   userInfo: [NSLocalizedDescriptionKey: "Not connected"]))
            return
        }
        
        // Placeholder for SSH command execution
        // In a real implementation, this would execute the command via SSH
        print("Would execute SSH command: \(command)")
        completion("Command executed (simulated)", nil)
    }
    
    // MARK: - Convenience Methods
    
    func startMotorController(completion: @escaping (Bool) -> Void) {
        executeCommand("python3 ~/yahboom-iphone-controller/pi/motor_controller.py &") { output, error in
            completion(error == nil)
        }
    }
    
    func startRTSPServer(completion: @escaping (Bool) -> Void) {
        executeCommand("python3 ~/yahboom-iphone-controller/pi/rtsp_server.py &") { output, error in
            completion(error == nil)
        }
    }
    
    func stopServices(completion: @escaping (Bool) -> Void) {
        executeCommand("pkill -f motor_controller.py && pkill -f rtsp_server.py") { output, error in
            completion(error == nil)
        }
    }
    
    // MARK: - Persistence
    
    private func saveCredentials() {
        UserDefaults.standard.set(host, forKey: "ssh_host")
        UserDefaults.standard.set(username, forKey: "ssh_username")
        // Note: In production, use Keychain for password storage
        UserDefaults.standard.set(password, forKey: "ssh_password")
    }
    
    private func loadCredentials() {
        host = UserDefaults.standard.string(forKey: "ssh_host")
        username = UserDefaults.standard.string(forKey: "ssh_username")
        password = UserDefaults.standard.string(forKey: "ssh_password")
    }
}
