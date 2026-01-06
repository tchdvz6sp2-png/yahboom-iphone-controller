//
//  TrackingViewModel.swift
//  YahboomController
//
//  View model for YOLOv8 person tracking
//

import Foundation
import Combine
import CoreGraphics

/// View model for person tracking
class TrackingViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var detections: [PersonDetection] = []
    @Published var isTracking = false
    @Published var isProcessing = false
    
    // MARK: - Properties
    
    private let tracker: PersonTracker
    private let settings: RobotSettings
    private let streamViewModel: StreamViewModel
    private let controlViewModel: ControlViewModel
    
    private var trackingTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(settings: RobotSettings, 
         streamViewModel: StreamViewModel,
         controlViewModel: ControlViewModel) {
        self.settings = settings
        self.streamViewModel = streamViewModel
        self.controlViewModel = controlViewModel
        
        // Create tracker with current confidence threshold
        self.tracker = PersonTracker(confidenceThreshold: settings.confidenceThreshold)
        
        // Observe tracking enabled state
        settings.$trackingEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled in
                if enabled {
                    self?.startTracking()
                } else {
                    self?.stopTracking()
                }
            }
            .store(in: &cancellables)
        
        // Observe detections from tracker
        tracker.$detections
            .receive(on: DispatchQueue.main)
            .assign(to: &$detections)
        
        tracker.$isProcessing
            .receive(on: DispatchQueue.main)
            .assign(to: &$isProcessing)
    }
    
    // MARK: - Tracking Control
    
    func startTracking() {
        guard !isTracking else { return }
        
        print("[Tracking] Starting person tracking")
        isTracking = true
        
        // Process frames periodically (15-30 FPS depending on performance)
        trackingTimer = Timer.scheduledTimer(
            withTimeInterval: 1.0 / 20.0, // 20 FPS tracking
            repeats: true
        ) { [weak self] _ in
            self?.processFrame()
        }
    }
    
    func stopTracking() {
        guard isTracking else { return }
        
        print("[Tracking] Stopping person tracking")
        isTracking = false
        
        trackingTimer?.invalidate()
        trackingTimer = nil
        
        detections = []
    }
    
    // MARK: - Frame Processing
    
    private func processFrame() {
        guard isTracking else { return }
        guard !isProcessing else { return } // Skip if still processing
        
        // Get current video frame
        guard let frame = streamViewModel.getCurrentFrame() else {
            return
        }
        
        // Run detection
        tracker.detect(in: frame)
        
        // If tracking is active and not in manual control, send tracking command
        if !controlViewModel.isManualControlActive,
           let command = tracker.calculateTrackingCommand(
            frameWidth: CGFloat(frame.width),
            trackingSpeed: settings.trackingSpeed.speedMultiplier
           ) {
            controlViewModel.sendCommand(command)
        }
    }
    
    // MARK: - Cleanup
    
    deinit {
        stopTracking()
    }
}
