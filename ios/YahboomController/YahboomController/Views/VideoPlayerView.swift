//
//  VideoPlayerView.swift
//  YahboomController
//
//  RTSP video player view using AVFoundation
//

import UIKit
import AVFoundation

class VideoPlayerView: UIView {
    
    // MARK: - Properties
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var playerItem: AVPlayerItem?
    
    private var isPlaying = false
    private var streamURL: String?
    
    // Placeholder view when no stream
    private let placeholderLabel = UILabel()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - Setup
    
    private func setupView() {
        backgroundColor = .black
        
        // Placeholder
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        placeholderLabel.text = "No Video Stream"
        placeholderLabel.textColor = .white
        placeholderLabel.textAlignment = .center
        placeholderLabel.font = .systemFont(ofSize: 18, weight: .medium)
        addSubview(placeholderLabel)
        
        NSLayoutConstraint.activate([
            placeholderLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            placeholderLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
    }
    
    // MARK: - Stream Control
    
    func startStream(url: String) {
        guard let streamURL = URL(string: url) else {
            print("Invalid stream URL: \(url)")
            return
        }
        
        self.streamURL = url
        
        // Create player item
        playerItem = AVPlayerItem(url: streamURL)
        
        // Create player
        player = AVPlayer(playerItem: playerItem)
        
        // Create player layer
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = bounds
        playerLayer?.videoGravity = .resizeAspect
        
        if let playerLayer = playerLayer {
            layer.addSublayer(playerLayer)
        }
        
        // Hide placeholder
        placeholderLabel.isHidden = true
        
        // Start playback
        player?.play()
        isPlaying = true
        
        // Observe player status
        setupObservers()
        
        print("Started RTSP stream: \(url)")
    }
    
    func stopStream() {
        player?.pause()
        player = nil
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        playerItem = nil
        
        isPlaying = false
        placeholderLabel.isHidden = false
        
        print("Stopped video stream")
    }
    
    // MARK: - Observers
    
    private func setupObservers() {
        // Observe player item status
        playerItem?.addObserver(self, 
                               forKeyPath: "status", 
                               options: [.new], 
                               context: nil)
        
        // Observe when playback stalls
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerStalled),
            name: .AVPlayerItemPlaybackStalled,
            object: playerItem
        )
        
        // Observe when playback ends
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )
    }
    
    override func observeValue(forKeyPath keyPath: String?, 
                              of object: Any?, 
                              change: [NSKeyValueChangeKey : Any]?, 
                              context: UnsafeMutableRawPointer?) {
        
        if keyPath == "status" {
            if let status = playerItem?.status {
                switch status {
                case .readyToPlay:
                    print("Player ready to play")
                case .failed:
                    print("Player failed: \(playerItem?.error?.localizedDescription ?? "unknown error")")
                    handleStreamError()
                case .unknown:
                    print("Player status unknown")
                @unknown default:
                    break
                }
            }
        }
    }
    
    @objc private func playerStalled() {
        print("Playback stalled - attempting to recover")
        player?.play()
    }
    
    @objc private func playerDidFinishPlaying() {
        print("Playback finished")
        // For live streams, this shouldn't happen, but handle it anyway
        if let url = streamURL {
            stopStream()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.startStream(url: url)
            }
        }
    }
    
    private func handleStreamError() {
        placeholderLabel.text = "Stream Error - Reconnecting..."
        placeholderLabel.isHidden = false
        
        // Attempt to reconnect after delay
        if let url = streamURL {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.stopStream()
                self?.startStream(url: url)
            }
        }
    }
    
    // MARK: - Deinitialization
    
    deinit {
        stopStream()
        NotificationCenter.default.removeObserver(self)
        playerItem?.removeObserver(self, forKeyPath: "status")
    }
}
