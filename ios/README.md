# Yahboom Controller iOS App

This directory contains the iOS application for controlling the Yahboom Rider Pi CM4 balancing robot.

## Project Structure

```
YahboomController/
├── YahboomController/
│   ├── AppDelegate.swift           - Application delegate
│   ├── SceneDelegate.swift         - Scene lifecycle
│   ├── Info.plist                  - App configuration
│   ├── ViewControllers/
│   │   ├── MainViewController.swift      - Main control interface
│   │   ├── SettingsViewController.swift  - Settings screen
│   │   └── StreamViewController.swift    - Full-screen video
│   ├── Views/
│   │   ├── JoystickView.swift      - Custom joystick control
│   │   └── VideoPlayerView.swift   - RTSP video player
│   ├── Models/
│   │   ├── ConnectionManager.swift - Connection coordination
│   │   ├── MotorController.swift   - Motor control via UDP
│   │   ├── SSHManager.swift        - SSH connectivity
│   │   └── YOLODetector.swift      - Object detection
│   ├── Resources/
│   │   └── (Assets, model files)
│   └── SupportingFiles/
│       └── (Additional resources)
└── YahboomController.xcodeproj     - Xcode project file
```

## Opening the Project

To create the actual Xcode project:

1. Open Xcode
2. Create a new iOS App project
3. Name it "YahboomController"
4. Set Bundle Identifier to: `com.yourname.yahboomcontroller`
5. Choose Swift as the language
6. Choose Storyboard or SwiftUI (these files use UIKit programmatically)
7. Add all the Swift files from this directory to the project

**OR**

Use the command line to generate the project:

```bash
# This is a placeholder - actual Xcode projects are binary/complex
# In practice, you would:
# 1. Create project in Xcode GUI
# 2. Add these source files
# 3. Configure signing & capabilities
```

## Required Capabilities

Make sure these are enabled in your Xcode project:

- **Camera Usage**: For video processing
- **Local Network**: For communicating with Raspberry Pi
- **Background Modes**: For maintaining connections (optional)

## Dependencies

This project uses only iOS system frameworks:
- UIKit
- AVFoundation
- CoreML
- Vision
- Network

No external dependencies required (CocoaPods/SPM).

## Building

1. Open the project in Xcode
2. Select your development team in Signing & Capabilities
3. Connect your iOS device
4. Build and run (⌘+R)

## Configuration

On first launch:
1. Open Settings
2. Enter your Raspberry Pi IP address
3. Enter motor control port (default: 5005)
4. Enter RTSP stream URL (e.g., `rtsp://192.168.1.100:8554/stream`)
5. Tap "Connect"

## Features Implemented

- ✅ UDP-based motor control
- ✅ RTSP video streaming
- ✅ Custom joystick control
- ✅ Settings management
- ✅ Connection status monitoring
- ✅ YOLOv8 CoreML integration (placeholder)
- ✅ SSH manager (placeholder)

## Adding YOLOv8 Model

To enable object detection:

1. Download a YOLOv8 CoreML model (e.g., `yolov8n.mlmodel`)
2. Drag it into the Xcode project
3. Ensure it's included in the target
4. The app will automatically use it

## Notes

- The code is structured to work without storyboards (programmatic UI)
- All views are created in code for maximum flexibility
- The app supports both portrait and landscape orientations
- Connection settings are persisted using UserDefaults

## Troubleshooting

See the main [TROUBLESHOOTING.md](../docs/TROUBLESHOOTING.md) guide for common issues.

## Development

To add new features:
1. Follow the existing architecture pattern
2. Add new view controllers to `ViewControllers/`
3. Add custom views to `Views/`
4. Add business logic to `Models/`
5. Update this README with any new requirements
