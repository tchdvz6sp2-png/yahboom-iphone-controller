//
//  DetectionOverlayView.swift
//  YahboomController
//
//  SwiftUI view for displaying object detection bounding boxes
//

import SwiftUI

struct DetectionOverlayView: View {
    
    let detections: [YOLODetector.Detection]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(Array(detections.enumerated()), id: \.offset) { index, detection in
                    DetectionBox(
                        detection: detection,
                        frameSize: geometry.size
                    )
                }
            }
        }
    }
}

struct DetectionBox: View {
    
    let detection: YOLODetector.Detection
    let frameSize: CGSize
    
    var body: some View {
        let rect = convertBoundingBox(detection.boundingBox, in: frameSize)
        
        ZStack(alignment: .topLeading) {
            Rectangle()
                .stroke(Color.green, lineWidth: 2)
                .frame(width: rect.width, height: rect.height)
                .position(x: rect.midX, y: rect.midY)
            
            Text("\(detection.label) \(Int(detection.confidence * 100))%")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .padding(4)
                .background(Color.green.opacity(0.7))
                .cornerRadius(4)
                .position(x: rect.minX + rect.width / 2, y: rect.minY - 12)
        }
    }
    
    private func convertBoundingBox(_ box: CGRect, in frameSize: CGSize) -> CGRect {
        // Vision framework uses normalized coordinates with origin at bottom-left
        // Convert to SwiftUI coordinates with origin at top-left
        
        let x = box.minX * frameSize.width
        let y = (1 - box.maxY) * frameSize.height
        let width = box.width * frameSize.width
        let height = box.height * frameSize.height
        
        return CGRect(x: x, y: y, width: width, height: height)
    }
}

#Preview {
    DetectionOverlayView(detections: [
        YOLODetector.Detection(
            label: "person",
            confidence: 0.95,
            boundingBox: CGRect(x: 0.3, y: 0.3, width: 0.4, height: 0.4)
        )
    ])
    .frame(width: 300, height: 400)
    .background(Color.black)
}
