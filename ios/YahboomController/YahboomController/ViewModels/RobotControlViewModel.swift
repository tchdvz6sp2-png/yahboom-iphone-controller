//
//  RobotControlViewModel.swift
//  YahboomController
//
//  Main ViewModel for robot control with MVVM architecture
//

import Foundation
import Combine
import AVFoundation

@MainActor
class RobotControlViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isConnected: Bool = false
    @Published var connectionStatus: String = "Disconnected"
    @Published var detections: [YOLODetector.Detection] = []
    @Published var isTrackingEnabled: Bool = false
    @Published var videoURL: String?
    @Published var emergencyStopActive: Bool = false
    
    // MARK: - Private Properties
    private var motorController: MotorController?
    private var yoloDetector = YOLODetector()
    private var joystickUpdateTimer: Timer?
    private var connectionMonitorTimer: Timer?
    private var lastCommandTime: Date?
    private var cancellables = Set<AnyCancellable>()
    
    // Current joystick position
    private var currentJoystickX: Double = 0
    private var currentJoystickY: Double = 0
    
    // Connection timeout (1 second)
    private let connectionTimeout: TimeInterval = 1.0
    
    // MARK: - Initialization
    init() {
        setupConnectionMonitoring()
        loadSettings()
    }
    
    // MARK: - Public Methods
    
    func connect(ipAddress: String, port: Int, rtspURL: String) {
        motorController = MotorController(ipAddress: ipAddress, port: port)
        videoURL = rtspURL
        
        motorController?.testConnection { [weak self] success in
            Task { @MainActor in
                self?.isConnected = success
                self?.connectionStatus = success ? "Connected" : "Connection Failed"
                
                if success {
                    self?.startJoystickTimer()
                    self?.startConnectionMonitor()
                    self?.lastCommandTime = Date()
                } else {
                    self?.handleDisconnection()
                }
            }
        }
        
        // Save settings
        UserDefaults.standard.set(ipAddress, forKey: "pi_ip_address")
        UserDefaults.standard.set(port, forKey: "motor_port")
        UserDefaults.standard.set(rtspURL, forKey: "rtsp_url")
    }
    
    func disconnect() {
        stopJoystickTimer()
        stopConnectionMonitor()
        motorController?.disconnect()
        motorController = nil
        isConnected = false
        connectionStatus = "Disconnected"
        videoURL = nil
        emergencyStopActive = false
    }
    
    func updateJoystickPosition(x: Double, y: Double) {
        currentJoystickX = x
        currentJoystickY = y
    }
    
    func joystickReleased() {
        currentJoystickX = 0
        currentJoystickY = 0
        motorController?.stop()
        lastCommandTime = Date()
    }
    
    func triggerEmergencyStop() {
        emergencyStopActive = true
        currentJoystickX = 0
        currentJoystickY = 0
        motorController?.stop()
        lastCommandTime = Date()
    }
    
    func resetEmergencyStop() {
        emergencyStopActive = false
    }
    
    func toggleTracking() {
        isTrackingEnabled.toggle()
        yoloDetector.isEnabled = isTrackingEnabled
        if !isTrackingEnabled {
            detections = []
        }
    }
    
    func processVideoFrame(_ pixelBuffer: CVPixelBuffer) {
        guard isTrackingEnabled else { return }
        
        yoloDetector.detect(in: pixelBuffer) { [weak self] detections in
            Task { @MainActor in
                self?.detections = detections
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func loadSettings() {
        if let rtspURL = UserDefaults.standard.string(forKey: "rtsp_url") {
            videoURL = rtspURL
        }
    }
    
    private func setupConnectionMonitoring() {
        // Setup will be done when connection is established
    }
    
    private func startJoystickTimer() {
        // Send joystick commands at 20Hz (every 0.05 seconds)
        // Note: @MainActor ensures timer callback runs on main thread
        joystickUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.sendJoystickCommand()
        }
    }
    
    private func stopJoystickTimer() {
        joystickUpdateTimer?.invalidate()
        joystickUpdateTimer = nil
    }
    
    private func sendJoystickCommand() {
        guard !emergencyStopActive, isConnected else { return }
        
        motorController?.setJoystickPosition(x: currentJoystickX, y: currentJoystickY)
        lastCommandTime = Date()
    }
    
    private func startConnectionMonitor() {
        // Check connection status every 0.1 seconds
        // Note: @MainActor ensures timer callback runs on main thread
        connectionMonitorTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.checkConnectionTimeout()
        }
    }
    
    private func stopConnectionMonitor() {
        connectionMonitorTimer?.invalidate()
        connectionMonitorTimer = nil
    }
    
    private func checkConnectionTimeout() {
        guard let lastCommandTime = lastCommandTime else { return }
        
        let timeSinceLastCommand = Date().timeIntervalSince(lastCommandTime)
        
        if timeSinceLastCommand > connectionTimeout && !emergencyStopActive {
            // Connection lost for more than 1 second - trigger emergency stop
            triggerEmergencyStop()
            connectionStatus = "Connection Lost - Emergency Stop"
        }
    }
    
    private func handleDisconnection() {
        stopJoystickTimer()
        stopConnectionMonitor()
        isConnected = false
        emergencyStopActive = false
    }
    
    // MARK: - Deinitialization
    deinit {
        stopJoystickTimer()
        stopConnectionMonitor()
    }
}
