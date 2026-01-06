//
//  PersonDetection.swift
//  YahboomController
//
//  Model for YOLOv8 person detection results
//

import Foundation
import CoreGraphics

/// Represents a detected person in the video frame
struct PersonDetection: Identifiable {
    /// Unique identifier
    let id = UUID()
    
    /// Bounding box in normalized coordinates (0.0 to 1.0)
    let boundingBox: CGRect
    
    /// Confidence score (0.0 to 1.0)
    let confidence: Double
    
    /// Class label (should be "person" for person tracking)
    let label: String
    
    /// Center point of the detection
    var centerPoint: CGPoint {
        return CGPoint(
            x: boundingBox.midX,
            y: boundingBox.midY
        )
    }
    
    /// Calculate horizontal offset from center of frame
    /// Returns -1.0 (left) to 1.0 (right), 0.0 is centered
    func horizontalOffset(frameWidth: CGFloat) -> Double {
        let frameCenterX = 0.5
        let personCenterX = boundingBox.midX
        return Double((personCenterX - frameCenterX) * 2.0)
    }
    
    /// Calculate distance estimation based on bounding box size
    /// Larger box = closer person
    var estimatedDistance: Double {
        // Simple inverse relationship: larger box = smaller distance value
        let boxArea = boundingBox.width * boundingBox.height
        return 1.0 - min(boxArea, 1.0)
    }
}
