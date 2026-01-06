//
//  RobotSettings.swift
//  YahboomController
//
//  Settings model for robot connection and configuration
//

import Foundation

/// Robot connection and control settings
class RobotSettings: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Robot connection settings
    @Published var robotIP: String {
        didSet { UserDefaults.standard.set(robotIP, forKey: "robotIP") }
    }
    
    @Published var sshPort: Int {
        didSet { UserDefaults.standard.set(sshPort, forKey: "sshPort") }
    }
    
    @Published var sshUsername: String {
        didSet { UserDefaults.standard.set(sshUsername, forKey: "sshUsername") }
    }
    
    /// RTSP streaming settings
    @Published var rtspURL: String {
        didSet { UserDefaults.standard.set(rtspURL, forKey: "rtspURL") }
    }
    
    /// Motor control settings
    @Published var udpPort: Int {
        didSet { UserDefaults.standard.set(udpPort, forKey: "udpPort") }
    }
    
    @Published var controlUpdateRate: Int {
        didSet { UserDefaults.standard.set(controlUpdateRate, forKey: "controlUpdateRate") }
    }
    
    /// Person tracking settings
    @Published var trackingEnabled: Bool {
        didSet { UserDefaults.standard.set(trackingEnabled, forKey: "trackingEnabled") }
    }
    
    @Published var confidenceThreshold: Double {
        didSet { UserDefaults.standard.set(confidenceThreshold, forKey: "confidenceThreshold") }
    }
    
    @Published var trackingSpeed: TrackingSpeed {
        didSet { UserDefaults.standard.set(trackingSpeed.rawValue, forKey: "trackingSpeed") }
    }
    
    // MARK: - Initialization
    
    init() {
        // Load from UserDefaults or use defaults
        self.robotIP = UserDefaults.standard.string(forKey: "robotIP") ?? "192.168.1.100"
        self.sshPort = UserDefaults.standard.integer(forKey: "sshPort") != 0 
            ? UserDefaults.standard.integer(forKey: "sshPort") : 22
        self.sshUsername = UserDefaults.standard.string(forKey: "sshUsername") ?? "pi"
        
        self.rtspURL = UserDefaults.standard.string(forKey: "rtspURL") 
            ?? "rtsp://192.168.1.100:8554/stream"
        
        self.udpPort = UserDefaults.standard.integer(forKey: "udpPort") != 0 
            ? UserDefaults.standard.integer(forKey: "udpPort") : 5000
        self.controlUpdateRate = UserDefaults.standard.integer(forKey: "controlUpdateRate") != 0 
            ? UserDefaults.standard.integer(forKey: "controlUpdateRate") : 20
        
        self.trackingEnabled = UserDefaults.standard.bool(forKey: "trackingEnabled")
        self.confidenceThreshold = UserDefaults.standard.double(forKey: "confidenceThreshold") != 0 
            ? UserDefaults.standard.double(forKey: "confidenceThreshold") : 0.5
        
        let speedRaw = UserDefaults.standard.string(forKey: "trackingSpeed") ?? "medium"
        self.trackingSpeed = TrackingSpeed(rawValue: speedRaw) ?? .medium
    }
    
    // MARK: - Computed Properties
    
    /// Full RTSP URL (auto-generated if using default format)
    var fullRTSPURL: String {
        if rtspURL.starts(with: "rtsp://") {
            return rtspURL
        } else {
            return "rtsp://\(robotIP):8554/stream"
        }
    }
    
    /// Update interval for motor commands (in seconds)
    var updateInterval: TimeInterval {
        return 1.0 / Double(controlUpdateRate)
    }
}

// MARK: - Supporting Types

/// Tracking speed options
enum TrackingSpeed: String, CaseIterable, Identifiable {
    case slow = "slow"
    case medium = "medium"
    case fast = "fast"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .slow: return "Slow (30%)"
        case .medium: return "Medium (50%)"
        case .fast: return "Fast (70%)"
        }
    }
    
    var speedMultiplier: Double {
        switch self {
        case .slow: return 0.3
        case .medium: return 0.5
        case .fast: return 0.7
        }
    }
}
