//
//  StreamViewModel.swift
//  YahboomController
//
//  View model for RTSP video streaming
//

import Foundation
import AVKit
import Combine

/// View model for video streaming
class StreamViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isStreaming = false
    @Published var currentFPS: Double = 0
    @Published var latency: TimeInterval = 0
    @Published var error: Error?
    
    // MARK: - Properties
    
    let rtspPlayer = RTSPPlayer()
    private let settings: RobotSettings
    private let connectionViewModel: ConnectionViewModel
    private var cancellables = Set<AnyCancellable>()
    
    // Expose player for SwiftUI VideoPlayer
    var player: AVPlayer? {
        return rtspPlayer.player
    }
    
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
        
        // Observe player state
        rtspPlayer.$isPlaying
            .receive(on: DispatchQueue.main)
            .assign(to: &$isStreaming)
        
        rtspPlayer.$currentFPS
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentFPS)
        
        rtspPlayer.$latency
            .receive(on: DispatchQueue.main)
            .assign(to: &$latency)
        
        rtspPlayer.$error
            .receive(on: DispatchQueue.main)
            .assign(to: &$error)
    }
    
    // MARK: - Connection Handling
    
    private func handleConnectionStateChange(_ state: ConnectionState) {
        switch state {
        case .connected:
            startStream()
        case .disconnected, .error:
            stopStream()
        default:
            break
        }
    }
    
    // MARK: - Stream Control
    
    /// Start RTSP video stream
    func startStream() {
        print("[Stream] Starting stream: \(settings.fullRTSPURL)")
        rtspPlayer.setup(urlString: settings.fullRTSPURL)
        rtspPlayer.play()
    }
    
    /// Stop video stream
    func stopStream() {
        print("[Stream] Stopping stream")
        rtspPlayer.stop()
    }
    
    /// Get current video frame for tracking
    func getCurrentFrame() -> CGImage? {
        return rtspPlayer.getCurrentFrame()
    }
    
    // MARK: - Cleanup
    
    deinit {
        stopStream()
    }
}
