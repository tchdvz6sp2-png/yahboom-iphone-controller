//
//  SettingsViewModel.swift
//  YahboomController
//
//  ViewModel for settings management with persistent storage
//

import Foundation
import Combine

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

@MainActor
class SettingsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var ipAddress: String = ""
    @Published var motorPort: String = "5005"
    @Published var rtspURL: String = ""
    @Published var videoResolution: VideoResolution = .hd720
    
    // MARK: - Video Resolution Options
    enum VideoResolution: String, CaseIterable {
        case sd480 = "640x480"
        case hd720 = "1280x720"
        case hd1080 = "1920x1080"
        
        var displayName: String {
            switch self {
            case .sd480: return "SD (480p)"
            case .hd720: return "HD (720p)"
            case .hd1080: return "Full HD (1080p)"
            }
        }
    }
    
    // MARK: - Initialization
    init() {
        loadSettings()
    }
    
    // MARK: - Public Methods
    
    func loadSettings() {
        ipAddress = UserDefaults.standard.string(forKey: "pi_ip_address") ?? ""
        
        let port = UserDefaults.standard.integer(forKey: "motor_port")
        motorPort = port > 0 ? String(port) : "5005"
        
        rtspURL = UserDefaults.standard.string(forKey: "rtsp_url") ?? ""
        
        if let resolutionString = UserDefaults.standard.string(forKey: "video_resolution"),
           let resolution = VideoResolution(rawValue: resolutionString) {
            videoResolution = resolution
        }
    }
    
    func saveSettings() {
        UserDefaults.standard.set(ipAddress, forKey: "pi_ip_address")
        
        if let port = Int(motorPort) {
            UserDefaults.standard.set(port, forKey: "motor_port")
        }
        
        UserDefaults.standard.set(rtspURL, forKey: "rtsp_url")
        UserDefaults.standard.set(videoResolution.rawValue, forKey: "video_resolution")
    }
    
    func validateSettings() -> (isValid: Bool, errorMessage: String?) {
        // Validate IP address
        guard !ipAddress.isEmpty else {
            return (false, "IP address is required")
        }
        
        // Robust IP address validation using inet_pton
        var sin = sockaddr_in()
        if inet_pton(AF_INET, ipAddress, &sin.sin_addr) != 1 {
            return (false, "Invalid IP address format")
        }
        
        // Validate port
        guard let port = Int(motorPort), port > 0 && port <= 65535 else {
            return (false, "Port must be between 1 and 65535")
        }
        
        // Validate RTSP URL
        guard !rtspURL.isEmpty else {
            return (false, "RTSP URL is required")
        }
        
        guard rtspURL.lowercased().hasPrefix("rtsp://") else {
            return (false, "RTSP URL must start with rtsp://")
        }
        
        return (true, nil)
    }
    
    func getMotorPort() -> Int {
        return Int(motorPort) ?? 5005
    }
    
    func autoFillRTSPURL() {
        if !ipAddress.isEmpty && rtspURL.isEmpty {
            rtspURL = "rtsp://\(ipAddress):8554/stream"
        }
    }
}
