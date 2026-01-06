//
//  StreamView.swift
//  YahboomController
//
//  Video stream display with person detection overlays
//

import SwiftUI
import AVKit

struct StreamView: View {
    
    // MARK: - Properties
    
    @ObservedObject var viewModel: StreamViewModel
    let detections: [PersonDetection]
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Video player
                if let player = viewModel.player {
                    VideoPlayer(player: player)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                } else {
                    // Placeholder when no stream
                    ZStack {
                        Color.black
                        
                        VStack(spacing: 20) {
                            Image(systemName: "video.slash")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            
                            Text("No Stream")
                                .font(.title2)
                                .foregroundColor(.gray)
                            
                            if let error = viewModel.error {
                                Text(error.localizedDescription)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                                    .padding()
                            }
                        }
                    }
                }
                
                // Person detection overlays
                ForEach(detections) { detection in
                    DetectionBox(detection: detection, frameSize: geometry.size)
                }
                
                // Stream info overlay
                VStack {
                    Spacer()
                    
                    HStack {
                        if viewModel.isStreaming {
                            Text("FPS: \(Int(viewModel.currentFPS))")
                                .font(.caption)
                                .padding(8)
                                .background(Color.black.opacity(0.6))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        
                        Spacer()
                    }
                    .padding()
                }
            }
        }
    }
}

// MARK: - Detection Box View

struct DetectionBox: View {
    let detection: PersonDetection
    let frameSize: CGSize
    
    var body: some View {
        let box = convertBoundingBox(detection.boundingBox, frameSize: frameSize)
        
        ZStack {
            Rectangle()
                .stroke(Color.green, lineWidth: 2)
                .frame(width: box.width, height: box.height)
                .position(x: box.midX, y: box.midY)
            
            Text(String(format: "%.0f%%", detection.confidence * 100))
                .font(.caption)
                .padding(4)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(4)
                .position(x: box.minX + 30, y: box.minY - 10)
        }
    }
    
    /// Convert Vision normalized coordinates to view coordinates
    private func convertBoundingBox(_ box: CGRect, frameSize: CGSize) -> CGRect {
        // Vision uses bottom-left origin, flip Y coordinate
        let x = box.minX * frameSize.width
        let y = (1 - box.maxY) * frameSize.height
        let width = box.width * frameSize.width
        let height = box.height * frameSize.height
        
        return CGRect(x: x, y: y, width: width, height: height)
    }
}

// MARK: - Preview

struct StreamView_Previews: PreviewProvider {
    static var previews: some View {
        let settings = RobotSettings()
        let connectionVM = ConnectionViewModel(settings: settings)
        let streamVM = StreamViewModel(settings: settings, connectionViewModel: connectionVM)
        
        StreamView(viewModel: streamVM, detections: [])
    }
}
