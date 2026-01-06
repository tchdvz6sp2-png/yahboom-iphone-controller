//
//  MainControlView.swift
//  YahboomController
//
//  Main SwiftUI view for robot control interface
//

import SwiftUI

struct MainControlView: View {
    
    @StateObject private var viewModel = RobotControlViewModel()
    @State private var showSettings = false
    
    var body: some View {
        ZStack {
            // Video stream background
            VideoPlayerSwiftUIView(
                url: viewModel.videoURL,
                onFrameUpdate: { pixelBuffer in
                    viewModel.processVideoFrame(pixelBuffer)
                }
            )
            .ignoresSafeArea()
            
            // Detection overlay
            if viewModel.isTrackingEnabled {
                DetectionOverlayView(detections: viewModel.detections)
                    .ignoresSafeArea()
            }
            
            // Control overlay
            VStack {
                // Top bar with status and controls
                HStack {
                    // Connection status
                    HStack {
                        Circle()
                            .fill(viewModel.isConnected ? Color.green : Color.red)
                            .frame(width: 10, height: 10)
                        
                        Text(viewModel.connectionStatus)
                            .foregroundColor(.white)
                            .font(.system(size: 14, weight: .medium))
                    }
                    .padding(8)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(8)
                    
                    Spacer()
                    
                    // Tracking toggle
                    Button(action: {
                        viewModel.toggleTracking()
                    }) {
                        HStack {
                            Image(systemName: viewModel.isTrackingEnabled ? "eye.fill" : "eye.slash.fill")
                            Text(viewModel.isTrackingEnabled ? "Tracking On" : "Tracking Off")
                        }
                        .foregroundColor(.white)
                        .padding(8)
                        .background(viewModel.isTrackingEnabled ? Color.green.opacity(0.7) : Color.gray.opacity(0.7))
                        .cornerRadius(8)
                    }
                    
                    // Settings button
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "gear")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(8)
                    }
                }
                .padding()
                
                Spacer()
                
                // Bottom controls
                HStack(alignment: .bottom) {
                    // Joystick control
                    JoystickSwiftUIView(
                        onMove: { x, y in
                            viewModel.updateJoystickPosition(x: x, y: y)
                        },
                        onRelease: {
                            viewModel.joystickReleased()
                        }
                    )
                    .opacity(viewModel.emergencyStopActive ? 0.3 : 1.0)
                    .disabled(viewModel.emergencyStopActive || !viewModel.isConnected)
                    
                    Spacer()
                    
                    // Emergency stop button
                    VStack {
                        if viewModel.emergencyStopActive {
                            Button(action: {
                                viewModel.resetEmergencyStop()
                            }) {
                                VStack {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 24))
                                    Text("Reset")
                                        .font(.system(size: 14, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .frame(width: 100, height: 100)
                                .background(Color.orange)
                                .cornerRadius(50)
                            }
                        } else {
                            Button(action: {
                                viewModel.triggerEmergencyStop()
                            }) {
                                VStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 24))
                                    Text("STOP")
                                        .font(.system(size: 14, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .frame(width: 100, height: 100)
                                .background(Color.red)
                                .cornerRadius(50)
                            }
                        }
                    }
                }
                .padding()
            }
            
            // Emergency stop overlay
            if viewModel.emergencyStopActive {
                VStack {
                    Spacer()
                    Text("EMERGENCY STOP ACTIVE")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(8)
                    Spacer()
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(viewModel: viewModel)
        }
    }
}

#Preview {
    MainControlView()
}
