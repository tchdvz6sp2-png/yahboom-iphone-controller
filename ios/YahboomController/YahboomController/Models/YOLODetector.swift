//
//  YOLODetector.swift
//  YahboomController
//
//  CoreML YOLOv8 object detection wrapper
//

import Foundation
import CoreML
import Vision
import UIKit

class YOLODetector {
    
    // MARK: - Properties
    private var model: VNCoreMLModel?
    private let detectionQueue = DispatchQueue(label: "com.yahboom.yolodetection")
    
    var isEnabled: Bool = false
    var confidenceThreshold: Float = 0.5
    
    // MARK: - Detection Result
    struct Detection {
        let label: String
        let confidence: Float
        let boundingBox: CGRect
    }
    
    // MARK: - Initialization
    
    init() {
        setupModel()
    }
    
    private func setupModel() {
        // Note: This expects a YOLOv8 CoreML model named "yolov8n.mlmodel" in the project
        // The model file needs to be added to the Xcode project
        
        // Placeholder - in real implementation, load the actual model
        print("YOLODetector initialized (model loading placeholder)")
        
        // Example of how to load a CoreML model:
        // if let modelURL = Bundle.main.url(forResource: "yolov8n", withExtension: "mlmodelc") {
        //     do {
        //         let mlModel = try MLModel(contentsOf: modelURL)
        //         model = try VNCoreMLModel(for: mlModel)
        //     } catch {
        //         print("Failed to load CoreML model: \(error)")
        //     }
        // }
    }
    
    // MARK: - Detection
    
    func detect(in image: UIImage, completion: @escaping ([Detection]) -> Void) {
        guard isEnabled else {
            completion([])
            return
        }
        
        guard let model = model else {
            print("Model not loaded")
            completion([])
            return
        }
        
        guard let cgImage = image.cgImage else {
            completion([])
            return
        }
        
        detectionQueue.async { [weak self] in
            guard let self = self else { return }
            
            let request = VNCoreMLRequest(model: model) { request, error in
                if let error = error {
                    print("Detection error: \(error)")
                    completion([])
                    return
                }
                
                guard let results = request.results as? [VNRecognizedObjectObservation] else {
                    completion([])
                    return
                }
                
                let detections = results
                    .filter { $0.confidence >= self.confidenceThreshold }
                    .map { observation -> Detection in
                        let label = observation.labels.first?.identifier ?? "Unknown"
                        let confidence = observation.confidence
                        let boundingBox = observation.boundingBox
                        
                        return Detection(label: label, 
                                       confidence: confidence, 
                                       boundingBox: boundingBox)
                    }
                
                DispatchQueue.main.async {
                    completion(detections)
                }
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                print("Failed to perform detection: \(error)")
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }
    }
    
    func detect(in pixelBuffer: CVPixelBuffer, completion: @escaping ([Detection]) -> Void) {
        guard isEnabled else {
            completion([])
            return
        }
        
        guard let model = model else {
            completion([])
            return
        }
        
        detectionQueue.async { [weak self] in
            guard let self = self else { return }
            
            let request = VNCoreMLRequest(model: model) { request, error in
                if let error = error {
                    print("Detection error: \(error)")
                    completion([])
                    return
                }
                
                guard let results = request.results as? [VNRecognizedObjectObservation] else {
                    completion([])
                    return
                }
                
                let detections = results
                    .filter { $0.confidence >= self.confidenceThreshold }
                    .map { observation -> Detection in
                        let label = observation.labels.first?.identifier ?? "Unknown"
                        let confidence = observation.confidence
                        let boundingBox = observation.boundingBox
                        
                        return Detection(label: label, 
                                       confidence: confidence, 
                                       boundingBox: boundingBox)
                    }
                
                DispatchQueue.main.async {
                    completion(detections)
                }
            }
            
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                print("Failed to perform detection: \(error)")
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }
    }
}
