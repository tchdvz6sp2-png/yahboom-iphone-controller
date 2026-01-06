# iOS Xcode Project - YahboomController

## Project Structure

This iOS application is organized using the Model-View-ViewModel (MVVM) architecture pattern with SwiftUI.

### Directory Structure

```
YahboomController/
├── Models/                    # Data models
│   ├── RobotSettings.swift   # Settings and configuration
│   ├── MotorCommand.swift    # Motor command structure
│   └── PersonDetection.swift # Detection results
├── ViewModels/               # Business logic
│   ├── ConnectionViewModel.swift
│   ├── StreamViewModel.swift
│   ├── ControlViewModel.swift
│   └── TrackingViewModel.swift
├── Views/                    # SwiftUI views
│   ├── MainView.swift
│   ├── SettingsView.swift
│   ├── StreamView.swift
│   ├── JoystickView.swift
│   └── ConnectionIndicator.swift
├── Managers/                 # Services and utilities
│   ├── SSHManager.swift
│   ├── UDPClient.swift
│   ├── RTSPPlayer.swift
│   ├── KeychainManager.swift
│   └── PersonTracker.swift
└── Resources/               # Assets and resources
    ├── Assets.xcassets
    └── Info.plist
```

## Opening the Project in Xcode

### Method 1: Create New Xcode Project

1. Open Xcode
2. Create a new iOS App project:
   - File → New → Project
   - Choose "iOS" → "App"
   - Product Name: YahboomController
   - Interface: SwiftUI
   - Language: Swift
   - Minimum Deployment: iOS 15.0

3. Replace the generated files with the files from this repository:
   - Delete the default ContentView.swift
   - Add all files from the Models, ViewModels, Views, and Managers directories
   - Replace YahboomControllerApp.swift
   - Replace Info.plist

4. Add the Resources:
   - Replace Assets.xcassets with the one from Resources/

### Method 2: Manual Project File Creation

A complete .xcodeproj file has been created. To open:

1. Navigate to the ios/YahboomController directory
2. Double-click YahboomController.xcodeproj

## Build Settings

### Required Capabilities

- **Local Network Usage**: For connecting to the robot on local WiFi
- **Camera**: For person tracking (CoreML inference)

### Frameworks

The app uses only built-in iOS frameworks:
- SwiftUI
- AVFoundation (for video playback)
- CoreML & Vision (for person tracking)
- Network (for UDP/TCP communication)
- Security (for Keychain)

### Deployment Target

- Minimum: iOS 15.0
- Optimized for: iPhone 12 and later

## Adding YOLOv8 Model

To enable person tracking:

1. Export YOLOv8n model to CoreML format
2. Add the .mlmodel file to the project in Xcode
3. Ensure it's included in "Target Membership"
4. The PersonTracker will automatically load it

Without the model, the app will run but person tracking will be disabled.

## Building

### Debug Build

```bash
xcodebuild -scheme YahboomController -configuration Debug
```

### Release Build

```bash
xcodebuild -scheme YahboomController -configuration Release \
  -archivePath YahboomController.xcarchive archive
```

### Running on Device

1. Connect iPhone via USB
2. Select your iPhone as the target device in Xcode
3. Click Run (Cmd+R)

First time deployment requires trusting your developer account on the device:
- Settings → General → VPN & Device Management → Trust

## Configuration

Before first run:

1. Configure settings in the app's Settings page
2. Enter robot IP address
3. Enter SSH credentials (stored securely in Keychain)
4. Enter RTSP URL

Default settings:
- Robot IP: 192.168.1.100
- SSH Port: 22
- SSH Username: pi
- RTSP URL: rtsp://192.168.1.100:8554/stream
- UDP Port: 5000

## Troubleshooting

### App won't install
- Check signing & capabilities in Xcode
- Ensure your Apple ID is added to Xcode
- Trust the developer profile on device

### Video not showing
- Verify RTSP URL is correct
- Check robot RTSP server is running
- Ensure device and robot are on same network

### Joystick not working
- Ensure robot is connected (green indicator)
- Check motor controller is running on Pi
- Verify UDP port matches in Settings

## Notes

- The app requires active local network permission
- SSH connection is used for initial authentication
- Motor commands are sent via UDP for low latency
- Video streaming uses RTSP protocol
- All credentials are stored securely in iOS Keychain
