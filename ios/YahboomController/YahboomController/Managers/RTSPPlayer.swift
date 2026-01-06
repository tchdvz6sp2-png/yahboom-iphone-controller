//
//  RTSPPlayer.swift
//  YahboomController
//
//  RTSP video player using AVPlayer with low-latency configuration
//

import Foundation
import AVFoundation
import AVKit
import Combine

/// RTSP video player with low-latency optimizations
class RTSPPlayer: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isPlaying = false
    @Published var error: Error?
    @Published var currentFPS: Double = 0
    @Published var latency: TimeInterval = 0
    
    // MARK: - Properties
    
    private(set) var player: AVPlayer?
    private var timeObserver: Any?
    private var statusObserver: AnyCancellable?
    private var fpsTimer: Timer?
    private var frameCount: Int = 0
    
    // MARK: - Player Setup
    
    /// Setup player with RTSP URL
    /// - Parameter urlString: RTSP URL
    func setup(urlString: String) {
        guard let url = URL(string: urlString) else {
            print("[RTSP] Invalid URL: \(urlString)")
            error = NSError(domain: "RTSPPlayer", code: -1, 
                          userInfo: [NSLocalizedDescriptionKey: "Invalid RTSP URL"])
            return
        }
        
        print("[RTSP] Setting up player for: \(urlString)")
        
        // Create player item with asset
        let asset = AVURLAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        
        // Configure for low latency
        playerItem.preferredForwardBufferDuration = 1.0
        
        if #available(iOS 15.0, *) {
            playerItem.automaticallyPreservesTimeOffsetFromLive = false
        }
        
        // Create player
        player = AVPlayer(playerItem: playerItem)
        
        // Configure player for low latency
        player?.automaticallyWaitsToMinimizeStalling = false
        
        // Observe player status
        observePlayerStatus()
        
        // Start FPS monitoring
        startFPSMonitoring()
    }
    
    /// Start playing the stream
    func play() {
        player?.play()
        isPlaying = true
        print("[RTSP] Playing")
    }
    
    /// Pause the stream
    func pause() {
        player?.pause()
        isPlaying = false
        print("[RTSP] Paused")
    }
    
    /// Stop and cleanup
    func stop() {
        pause()
        cleanup()
        print("[RTSP] Stopped")
    }
    
    // MARK: - Monitoring
    
    private func observePlayerStatus() {
        guard let playerItem = player?.currentItem else { return }
        
        statusObserver = playerItem.publisher(for: \.status)
            .sink { [weak self] status in
                switch status {
                case .readyToPlay:
                    print("[RTSP] Ready to play")
                    self?.error = nil
                case .failed:
                    print("[RTSP] Failed: \(playerItem.error?.localizedDescription ?? "Unknown error")")
                    self?.error = playerItem.error
                    self?.isPlaying = false
                case .unknown:
                    print("[RTSP] Status unknown")
                @unknown default:
                    break
                }
            }
    }
    
    private func startFPSMonitoring() {
        fpsTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.currentFPS = Double(self.frameCount)
            self.frameCount = 0
        }
    }
    
    /// Called when a frame is displayed (call from video output delegate if available)
    func notifyFrameDisplayed() {
        frameCount += 1
    }
    
    // MARK: - Frame Extraction
    
    /// Get current video frame as CGImage (for person tracking)
    func getCurrentFrame() -> CGImage? {
        guard let playerItem = player?.currentItem else { return nil }
        
        let output = AVPlayerItemVideoOutput(pixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ])
        
        playerItem.add(output)
        
        let currentTime = playerItem.currentTime()
        
        if output.hasNewPixelBuffer(forItemTime: currentTime) {
            guard let pixelBuffer = output.copyPixelBuffer(
                forItemTime: currentTime,
                itemTimeForDisplay: nil
            ) else { return nil }
            
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let context = CIContext()
            
            return context.createCGImage(ciImage, from: ciImage.extent)
        }
        
        return nil
    }
    
    // MARK: - Cleanup
    
    private func cleanup() {
        fpsTimer?.invalidate()
        fpsTimer = nil
        
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
        
        statusObserver?.cancel()
        statusObserver = nil
        
        player = nil
    }
    
    deinit {
        cleanup()
    }
}
