//
//  MainView.swift
//  YahboomController
//
//  Main view combining video stream and joystick control
//

import SwiftUI

struct MainView: View {
    
    // MARK: - Environment
    
    @EnvironmentObject var settings: RobotSettings
    
    // MARK: - State
    
    @StateObject private var connectionVM: ConnectionViewModel
    @StateObject private var streamVM: StreamViewModel
    @StateObject private var controlVM: ControlViewModel
    @StateObject private var trackingVM: TrackingViewModel
    
    @State private var showSettings = false
    
    // MARK: - Initialization
    
    init() {
        // Note: This init pattern is a workaround for initializing StateObjects with dependencies
        // In production, consider using a dependency injection framework
        let tempSettings = RobotSettings()
        let connectionVM = ConnectionViewModel(settings: tempSettings)
        let streamVM = StreamViewModel(settings: tempSettings, connectionViewModel: connectionVM)
        let controlVM = ControlViewModel(settings: tempSettings, connectionViewModel: connectionVM)
        let trackingVM = TrackingViewModel(settings: tempSettings, streamViewModel: streamVM, controlViewModel: controlVM)
        
        _connectionVM = StateObject(wrappedValue: connectionVM)
        _streamVM = StateObject(wrappedValue: streamVM)
        _controlVM = StateObject(wrappedValue: controlVM)
        _trackingVM = StateObject(wrappedValue: trackingVM)
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Video Stream (top 2/3)
                    StreamView(viewModel: streamVM, detections: trackingVM.detections)
                        .frame(maxHeight: .infinity)
                    
                    // Joystick Control (bottom 1/3)
                    JoystickView(controlViewModel: controlVM)
                        .frame(height: 250)
                        .background(Color.black.opacity(0.8))
                }
                
                // Connection indicator overlay
                VStack {
                    HStack {
                        ConnectionIndicator(state: connectionVM.connectionState)
                            .padding()
                        
                        Spacer()
                        
                        // Settings button
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .padding()
                    }
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(settings)
            }
            .onAppear {
                // Auto-connect if credentials are saved
                if KeychainManager.exists(key: "ssh_password") {
                    connectionVM.connect()
                }
            }
            .onDisappear {
                // Disconnect when app goes to background
                connectionVM.disconnect()
                controlVM.emergencyStop()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Preview

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
            .environmentObject(RobotSettings())
    }
}
