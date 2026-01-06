//
//  ControlViewModel.swift
//  YahboomController
//
//  View model for motor control and joystick input
//

import Foundation
import Combine

/// View model for motor control
class ControlViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var currentSpeed: Int = 0
    @Published var currentDirection: Int = 0
    @Published var isManualControlActive = false
    
    // MARK: - Properties
    
    private let udpClient = UDPClient()
    private let settings: RobotSettings
    private let connectionViewModel: ConnectionViewModel
    
    private var updateTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(settings: RobotSettings, connectionViewModel: ConnectionViewModel) {
        self.settings = settings
        self.connectionViewModel = connectionViewModel
        
        // Observe connection state
        connectionViewModel.$connectionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleConnectionStateChange(state)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Connection Handling
    
    private func handleConnectionStateChange(_ state: ConnectionState) {
        switch state {
        case .connected:
            // Connect UDP client
            udpClient.connect(host: settings.robotIP, port: settings.udpPort)
            startCommandTimer()
            
        case .disconnected, .error:
            // Emergency stop and disconnect
            emergencyStop()
            udpClient.disconnect()
            stopCommandTimer()
            
        default:
            break
        }
    }
    
    // MARK: - Control Timer
    
    private func startCommandTimer() {
        // Send commands at configured rate (e.g., 20Hz)
        updateTimer = Timer.scheduledTimer(
            withTimeInterval: settings.updateInterval,
            repeats: true
        ) { [weak self] _ in
            self?.sendCurrentCommand()
        }
    }
    
    private func stopCommandTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    // MARK: - Command Sending
    
    private func sendCurrentCommand() {
        guard connectionViewModel.connectionState.isConnected else {
            return
        }
        
        let command = MotorCommand.move(
            speed: currentSpeed,
            direction: currentDirection
        )
        
        udpClient.send(command: command)
    }
    
    /// Update motor speed and direction from joystick
    /// - Parameters:
    ///   - speed: Forward/backward (-100 to 100)
    ///   - direction: Left/right (-100 to 100)
    func updateControl(speed: Int, direction: Int) {
        currentSpeed = speed
        currentDirection = direction
        isManualControlActive = (speed != 0 || direction != 0)
    }
    
    /// Send specific motor command
    /// - Parameter command: Command to send
    func sendCommand(_ command: MotorCommand) {
        guard connectionViewModel.connectionState.isConnected else {
            print("[Control] Not connected - command ignored")
            return
        }
        
        udpClient.send(command: command)
    }
    
    /// Emergency stop - immediately halt motors
    func emergencyStop() {
        print("[Control] EMERGENCY STOP")
        currentSpeed = 0
        currentDirection = 0
        isManualControlActive = false
        
        let stopCommand = MotorCommand.stop()
        udpClient.send(command: stopCommand)
    }
    
    /// Stop motors (normal stop)
    func stop() {
        updateControl(speed: 0, direction: 0)
    }
    
    // MARK: - Cleanup
    
    deinit {
        emergencyStop()
        stopCommandTimer()
        udpClient.disconnect()
    }
}
