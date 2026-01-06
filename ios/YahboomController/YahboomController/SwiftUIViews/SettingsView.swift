//
//  SettingsView.swift
//  YahboomController
//
//  SwiftUI settings view with persistent configuration
//

import SwiftUI

struct SettingsView: View {
    
    @StateObject private var settingsViewModel = SettingsViewModel()
    @ObservedObject var viewModel: RobotControlViewModel
    
    @Environment(\.dismiss) var dismiss
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Raspberry Pi Connection")) {
                    TextField("IP Address", text: $settingsViewModel.ipAddress)
                        .keyboardType(.decimalPad)
                        .autocapitalization(.none)
                        .onChange(of: settingsViewModel.ipAddress) { _ in
                            settingsViewModel.autoFillRTSPURL()
                        }
                    
                    TextField("Motor Port", text: $settingsViewModel.motorPort)
                        .keyboardType(.numberPad)
                }
                
                Section(header: Text("Video Stream")) {
                    TextField("RTSP URL", text: $settingsViewModel.rtspURL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    
                    Picker("Resolution", selection: $settingsViewModel.videoResolution) {
                        ForEach(SettingsViewModel.VideoResolution.allCases, id: \.self) { resolution in
                            Text(resolution.displayName).tag(resolution)
                        }
                    }
                    
                    Text("Example: rtsp://192.168.1.100:8554/stream")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("Connection")) {
                    if viewModel.isConnected {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Connected")
                            Spacer()
                            Button("Disconnect") {
                                viewModel.disconnect()
                            }
                            .foregroundColor(.red)
                        }
                    } else {
                        Button("Connect") {
                            connectToRobot()
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                
                Section(header: Text("Information")) {
                    HStack {
                        Text("App Version")
                        Spacer()
                        Text("1.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text("1")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSettings()
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert("Settings", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                settingsViewModel.loadSettings()
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func saveSettings() {
        let validation = settingsViewModel.validateSettings()
        
        if validation.isValid {
            settingsViewModel.saveSettings()
            alertMessage = "Settings saved successfully"
            showAlert = true
        } else {
            alertMessage = validation.errorMessage ?? "Invalid settings"
            showAlert = true
        }
    }
    
    private func connectToRobot() {
        let validation = settingsViewModel.validateSettings()
        
        if !validation.isValid {
            alertMessage = validation.errorMessage ?? "Invalid settings"
            showAlert = true
            return
        }
        
        // Save settings first
        settingsViewModel.saveSettings()
        
        // Connect to robot
        viewModel.connect(
            ipAddress: settingsViewModel.ipAddress,
            port: settingsViewModel.getMotorPort(),
            rtspURL: settingsViewModel.rtspURL
        )
        
        // Dismiss after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dismiss()
        }
    }
}

#Preview {
    SettingsView(viewModel: RobotControlViewModel())
}
