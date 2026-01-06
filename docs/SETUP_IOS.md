# iOS Application Setup Guide

This guide covers building and deploying the Yahboom Controller iOS application.

## Prerequisites

- Mac with macOS 12.0 (Monterey) or later
- Xcode 14.0 or later
- iOS device running iOS 15.0+
- Apple Developer account (for device deployment)
- CocoaPods installed (optional, if dependencies require it)

## Installation

### 1. Install Xcode

Download and install Xcode from the Mac App Store or [Apple Developer](https://developer.apple.com/xcode/).

### 2. Clone Repository

```bash
git clone https://github.com/tchdvz6sp2-png/yahboom-iphone-controller.git
cd yahboom-iphone-controller/ios
```

### 3. Install Dependencies (if needed)

If the project uses CocoaPods:

```bash
cd ios
pod install
# Open YahboomController.xcworkspace instead of .xcodeproj
```

If no Podfile exists, open the project directly:

```bash
open YahboomController.xcodeproj
```

## Project Configuration

### 1. Configure Signing & Capabilities

1. Open the project in Xcode
2. Select the project in the navigator
3. Select the "YahboomController" target
4. Go to "Signing & Capabilities" tab
5. Select your Team from the dropdown
6. Xcode will automatically manage provisioning profile

### 2. Update Bundle Identifier (if needed)

If you encounter signing issues:
1. Change the Bundle Identifier to something unique
2. Format: `com.yourname.yahboomcontroller`

### 3. Required Capabilities

The app requires these capabilities (should already be configured):
- **Camera Usage**: For video processing
- **Network**: For RTSP streaming and UDP communication
- **Background Modes**: For maintaining connections

## Building the Application

### Build for Simulator

1. Select an iOS Simulator from the device menu
2. Press ⌘+B or Product → Build
3. Press ⌘+R or Product → Run

### Build for Device

1. Connect your iOS device via USB
2. Trust the computer on your device if prompted
3. Select your device from the device menu
4. Press ⌘+R or Product → Run
5. On first run, you may need to trust the developer certificate on your device:
   - Settings → General → VPN & Device Management
   - Trust your developer certificate

## Configuration

### Configure Raspberry Pi Connection

On first launch, configure your Pi connection:

1. Open Settings in the app
2. Enter your Raspberry Pi details:
   - **IP Address**: Your Pi's IP (e.g., `192.168.1.100`)
   - **Motor Control Port**: UDP port (default: `5005`)
   - **RTSP Stream URL**: `rtsp://<pi-ip>:8554/stream`
   - **SSH Credentials**: Username and password for SSH access

### Test Connection

1. Ensure your Raspberry Pi scripts are running
2. In the app, tap "Test Connection"
3. Verify:
   - Motor control responds (try joystick)
   - Video stream appears
   - No error messages in console

## Project Structure

```
ios/YahboomController/
├── YahboomController.xcodeproj
└── YahboomController/
    ├── AppDelegate.swift
    ├── SceneDelegate.swift
    ├── Info.plist
    ├── ViewControllers/
    │   ├── MainViewController.swift
    │   ├── SettingsViewController.swift
    │   └── StreamViewController.swift
    ├── Views/
    │   ├── JoystickView.swift
    │   └── VideoPlayerView.swift
    ├── Models/
    │   ├── ConnectionManager.swift
    │   ├── MotorController.swift
    │   ├── SSHManager.swift
    │   └── YOLODetector.swift
    ├── Resources/
    │   ├── Assets.xcassets
    │   └── yolov8n.mlmodel
    └── Supporting Files/
```

## Features Overview

### Main View Controller
- Live video feed from Raspberry Pi
- Joystick control overlay
- Object detection visualization (YOLOv8)
- Connection status indicator

### Settings View Controller
- Raspberry Pi connection settings
- Motor control parameters
- Video quality settings
- SSH configuration

### Stream View Controller
- Full-screen video view
- Touch controls for camera movement
- Recording capabilities

## YOLOv8 Integration

### Add YOLOv8 Model

1. Download a YOLOv8 CoreML model (e.g., `yolov8n.mlmodel`)
2. Drag the model file into Xcode
3. Ensure "Target Membership" includes YahboomController
4. The app will automatically load and use the model

### Using Object Detection

1. Enable object detection in Settings
2. The main view will overlay detected objects
3. Detection runs on-device using CoreML

## Development Tips

### Enable Debug Logging

In `AppDelegate.swift`, enable verbose logging:
```swift
#if DEBUG
    // Enable detailed logging
    ConnectionManager.shared.debugMode = true
#endif
```

### Testing Without Hardware

The app includes simulation modes:
- Mock video stream (test pattern)
- Simulated motor responses
- Enable in Settings → Developer Options

### Performance Optimization

For best performance:
- Use H.264 codec for video streaming
- Limit video resolution to 640x480 for real-time response
- Disable object detection if not needed
- Close unused apps on your device

## Troubleshooting

### Build Errors

**"No profiles for 'com.example.yahboomcontroller' were found"**
- Solution: Change Bundle Identifier to something unique

**"Signing requires a development team"**
- Solution: Select your team in Signing & Capabilities

### Runtime Issues

**"Video stream not connecting"**
- Check Pi's IP address is correct
- Verify RTSP server is running on Pi
- Ensure devices are on same network

**"Motor control not responding"**
- Verify UDP port is correct
- Check motor_controller.py is running on Pi
- Test with test_motors.py on Pi first

**"Object detection not working"**
- Ensure YOLOv8 model is added to project
- Check model is included in target
- Verify iOS device supports CoreML

## Testing

### Run Unit Tests

```bash
# In Xcode
⌘+U or Product → Test
```

### Run UI Tests

Select a simulator or device and run UI tests to verify:
- Settings screen functionality
- Video playback
- Joystick controls
- Connection management

## Deployment

### TestFlight Distribution

1. Archive the app: Product → Archive
2. Upload to App Store Connect
3. Submit for TestFlight review
4. Share TestFlight link with testers

### Ad-Hoc Distribution

1. Archive the app
2. Export with Ad-Hoc distribution
3. Share .ipa file with testers
4. Install via Xcode or configurator

## Next Steps

- Customize UI colors and branding
- Add additional control modes
- Implement advanced features (autonomous navigation, etc.)
- Optimize for your specific robot configuration

## Resources

- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [Swift Programming Guide](https://docs.swift.org/swift-book/)
- [CoreML Documentation](https://developer.apple.com/documentation/coreml)
- [YOLOv8 Documentation](https://docs.ultralytics.com/)
