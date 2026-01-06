//
//  VideoPlayerSwiftUIView.swift
//  YahboomController
//
//  SwiftUI wrapper for AVFoundation RTSP video player
//

import SwiftUI
import AVFoundation

struct VideoPlayerSwiftUIView: UIViewRepresentable {
    
    let url: String?
    let onFrameUpdate: ((CVPixelBuffer) -> Void)?
    
    init(url: String?, onFrameUpdate: ((CVPixelBuffer) -> Void)? = nil) {
        self.url = url
        self.onFrameUpdate = onFrameUpdate
    }
    
    func makeUIView(context: Context) -> VideoPlayerUIView {
        let view = VideoPlayerUIView()
        view.onFrameUpdate = onFrameUpdate
        return view
    }
    
    func updateUIView(_ uiView: VideoPlayerUIView, context: Context) {
        if let url = url, !url.isEmpty {
            uiView.startStream(url: url)
        } else {
            uiView.stopStream()
        }
    }
    
    static func dismantleUIView(_ uiView: VideoPlayerUIView, coordinator: ()) {
        uiView.stopStream()
    }
}

// MARK: - VideoPlayerUIView

class VideoPlayerUIView: UIView {
    
    // MARK: - Properties
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var playerItem: AVPlayerItem?
    private var videoOutput: AVPlayerItemVideoOutput?
    private var displayLink: CADisplayLink?
    
    private var isPlaying = false
    private var streamURL: String?
    
    var onFrameUpdate: ((CVPixelBuffer) -> Void)?
    
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
        guard streamURL != url else { return }
        
        guard let streamURL = URL(string: url) else {
            print("Invalid stream URL: \(url)")
            return
        }
        
        self.streamURL = url
        
        // Create player item
        playerItem = AVPlayerItem(url: streamURL)
        
        // Setup video output for frame extraction
        let pixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: pixelBufferAttributes)
        if let videoOutput = videoOutput {
            playerItem?.add(videoOutput)
        }
        
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
        
        // Setup frame extraction
        setupDisplayLink()
        
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
        videoOutput = nil
        
        displayLink?.invalidate()
        displayLink = nil
        
        isPlaying = false
        streamURL = nil
        placeholderLabel.isHidden = false
        
        print("Stopped video stream")
    }
    
    // MARK: - Frame Extraction
    
    private func setupDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkDidRefresh))
        displayLink?.preferredFramesPerSecond = 30
        displayLink?.add(to: .main, forMode: .common)
    }
    
    @objc private func displayLinkDidRefresh() {
        guard let videoOutput = videoOutput,
              let playerItem = playerItem else { return }
        
        let currentTime = playerItem.currentTime()
        
        if videoOutput.hasNewPixelBuffer(forItemTime: currentTime),
           let pixelBuffer = videoOutput.copyPixelBuffer(forItemTime: currentTime, itemTimeForDisplay: nil) {
            onFrameUpdate?(pixelBuffer)
        }
    }
    
    // MARK: - Observers
    
    private var observerContext = 0
    private var isObserverAdded = false
    
    private func setupObservers() {
        // Observe player item status (with context to prevent crashes)
        if !isObserverAdded {
            playerItem?.addObserver(self, 
                                   forKeyPath: "status", 
                                   options: [.new], 
                                   context: &observerContext)
            isObserverAdded = true
        }
        
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
        
        // Check if this is our observer
        guard context == &observerContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        
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
        
        // Remove KVO observer safely
        if isObserverAdded {
            playerItem?.removeObserver(self, forKeyPath: "status", context: &observerContext)
            isObserverAdded = false
        }
    }
}
