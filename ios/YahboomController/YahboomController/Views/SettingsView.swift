//
//  SettingsView.swift
//  YahboomController
//
//  Settings and configuration view
//

import SwiftUI

struct SettingsView: View {
    
    // MARK: - Environment
    
    @EnvironmentObject var settings: RobotSettings
    @Environment(\.dismiss) var dismiss
    
    // MARK: - State
    
    @State private var password: String = ""
    @State private var showPasswordSaved = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            Form {
                // Robot Connection Section
                Section(header: Text("Robot Connection")) {
                    TextField("Robot IP Address", text: $settings.robotIP)
                        .keyboardType(.decimalPad)
                        .autocapitalization(.none)
                    
                    Stepper("SSH Port: \(settings.sshPort)", value: $settings.sshPort, in: 1...65535)
                    
                    TextField("SSH Username", text: $settings.sshUsername)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    
                    SecureField("SSH Password", text: $password)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    
                    Button("Save Password") {
                        savePassword()
                    }
                    .disabled(password.isEmpty)
                    
                    if showPasswordSaved {
                        Text("✓ Password saved securely")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
                
                // RTSP Streaming Section
                Section(header: Text("Video Streaming")) {
                    TextField("RTSP URL", text: $settings.rtspURL)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                    
                    Text("Example: rtsp://192.168.1.100:8554/stream")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // Motor Control Section
                Section(header: Text("Motor Control")) {
                    Stepper("UDP Port: \(settings.udpPort)", value: $settings.udpPort, in: 1...65535)
                    
                    Stepper("Update Rate: \(settings.controlUpdateRate) Hz", 
                           value: $settings.controlUpdateRate, in: 5...30)
                    
                    Text("Higher update rates provide smoother control but use more network bandwidth")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // Person Tracking Section
                Section(header: Text("Person Tracking")) {
                    Toggle("Enable Tracking", isOn: $settings.trackingEnabled)
                    
                    VStack(alignment: .leading) {
                        Text("Confidence Threshold: \(settings.confidenceThreshold, specifier: "%.2f")")
                        Slider(value: $settings.confidenceThreshold, in: 0.1...0.9, step: 0.05)
                    }
                    
                    Picker("Tracking Speed", selection: $settings.trackingSpeed) {
                        ForEach(TrackingSpeed.allCases) { speed in
                            Text(speed.displayName).tag(speed)
                        }
                    }
                    
                    Text("Person tracking requires YOLOv8 CoreML model to be included in the app")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // About Section
                Section(header: Text("About")) {
                    HStack {
                        Text("App Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("iOS Version")
                        Spacer()
                        Text(UIDevice.current.systemVersion)
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("Device")
                        Spacer()
                        Text(UIDevice.current.model)
                            .foregroundColor(.gray)
                    }
                }
                
                // Reset Section
                Section {
                    Button("Clear Saved Password") {
                        clearPassword()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
        .onAppear {
            loadPassword()
        }
    }
    
    // MARK: - Password Management
    
    private func savePassword() {
        KeychainManager.save(password: password, for: "ssh_password")
        
        withAnimation {
            showPasswordSaved = true
        }
        
        // Hide message after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showPasswordSaved = false
            }
        }
    }
    
    private func loadPassword() {
        if let savedPassword = KeychainManager.get(key: "ssh_password") {
            password = savedPassword
        }
    }
    
    private func clearPassword() {
        KeychainManager.delete(key: "ssh_password")
        password = ""
    }
}

// MARK: - Preview

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(RobotSettings())
    }
}
