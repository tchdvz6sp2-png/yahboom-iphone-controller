//
//  PersonTracker.swift
//  YahboomController
//
//  YOLOv8 person detection and tracking using CoreML
//
//  Note: This implementation assumes a YOLOv8n CoreML model is available.
//  The actual model file should be added to the project resources.
//

import Foundation
import CoreML
import Vision
import CoreGraphics
import UIKit

/// Person tracker using YOLOv8 CoreML model
class PersonTracker: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var detections: [PersonDetection] = []
    @Published var isProcessing = false
    
    // MARK: - Properties
    
    private var model: VNCoreMLModel?
    private let confidenceThreshold: Double
    
    // MARK: - Initialization
    
    init(confidenceThreshold: Double = 0.5) {
        self.confidenceThreshold = confidenceThreshold
        setupModel()
    }
    
    private func setupModel() {
        // Note: Replace with actual YOLOv8n model
        // For now, this is a placeholder
        
        // YOLOv8 CoreML Model Setup Instructions:
        //
        // 1. Export YOLOv8n model to CoreML format:
        //    Install ultralytics: pip install ultralytics
        //    Run in Python:
        //      from ultralytics import YOLO
        //      model = YOLO('yolov8n.pt')  # Downloads automatically if needed
        //      model.export(format='coreml', nms=True, imgsz=640)
        //    This creates YOLOv8n.mlpackage
        //
        // 2. Add model to Xcode project:
        //    - Drag YOLOv8n.mlpackage into Xcode project navigator
        //    - Ensure "Copy items if needed" is checked
        //    - Add to YahboomController target
        //    - Xcode will compile to .mlmodelc and generate Swift class
        //
        // 3. Uncomment the code below to load the model
        // 4. Model can be downloaded from: https://github.com/ultralytics/assets/releases
        //
        // Implementation code (uncomment when model is added):
        /*
        guard let modelURL = Bundle.main.url(forResource: "YOLOv8n", withExtension: "mlmodelc"),
              let mlModel = try? MLModel(contentsOf: modelURL),
              let visionModel = try? VNCoreMLModel(for: mlModel) else {
            print("[Tracker] Failed to load YOLOv8 model")
            return
        }
        
        self.model = visionModel
        print("[Tracker] YOLOv8n model loaded successfully")
        */
        
        print("[Tracker] Model setup incomplete - add YOLOv8n.mlmodel to enable person tracking")
        print("[Tracker] See PersonTracker.swift comments for detailed setup instructions")
    }
    
    // MARK: - Detection
    
    /// Process an image to detect persons
    /// - Parameter image: Image to process (CGImage or CIImage)
    func detect(in image: CGImage) {
        guard let model = model else {
            print("[Tracker] Model not loaded")
            return
        }
        
        isProcessing = true
        
        let request = VNCoreMLRequest(model: model) { [weak self] request, error in
            self?.handleDetectionResults(request: request, error: error)
        }
        
        // Configure request for optimal performance
        request.imageCropAndScaleOption = .scaleFill
        
        // Perform request
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("[Tracker] Detection error: \(error)")
                DispatchQueue.main.async {
                    self.isProcessing = false
                }
            }
        }
    }
    
    private func handleDetectionResults(request: VNRequest, error: Error?) {
        defer {
            DispatchQueue.main.async {
                self.isProcessing = false
            }
        }
        
        guard error == nil else {
            print("[Tracker] Request error: \(error!)")
            return
        }
        
        guard let results = request.results as? [VNRecognizedObjectObservation] else {
            return
        }
        
        // Filter for persons above confidence threshold
        let personDetections = results
            .filter { observation in
                // Check if this is a person detection
                guard let topLabel = observation.labels.first else { return false }
                return topLabel.identifier.lowercased().contains("person") &&
                       topLabel.confidence >= Float(confidenceThreshold)
            }
            .map { observation -> PersonDetection in
                let label = observation.labels.first?.identifier ?? "person"
                let confidence = Double(observation.labels.first?.confidence ?? 0)
                
                return PersonDetection(
                    boundingBox: observation.boundingBox,
                    confidence: confidence,
                    label: label
                )
            }
        
        DispatchQueue.main.async {
            self.detections = personDetections
        }
    }
    
    // MARK: - Tracking Logic
    
    /// Get the primary person to track (closest/largest)
    var primaryPerson: PersonDetection? {
        // Return the person with largest bounding box (closest to camera)
        return detections.max { a, b in
            let areaA = a.boundingBox.width * a.boundingBox.height
            let areaB = b.boundingBox.width * b.boundingBox.height
            return areaA < areaB
        }
    }
    
    /// Calculate motor command to track the primary person
    /// - Parameter frameWidth: Width of video frame
    /// - Returns: Motor command to center person in frame
    func calculateTrackingCommand(frameWidth: CGFloat, trackingSpeed: Double) -> MotorCommand? {
        guard let person = primaryPerson else {
            return nil
        }
        
        // Calculate horizontal offset (-1.0 to 1.0)
        let offset = person.horizontalOffset(frameWidth: frameWidth)
        
        // Convert to turn command
        let turnCommand = Int(offset * 100.0)
        
        // Calculate forward speed based on distance
        // Closer person = slower approach
        let distance = person.estimatedDistance
        let forwardSpeed = Int(distance * 100.0 * trackingSpeed)
        
        return MotorCommand.move(
            speed: forwardSpeed,
            direction: turnCommand
        )
    }
}
