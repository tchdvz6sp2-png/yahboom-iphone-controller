# iOS Application Setup Guide

This guide covers building and deploying the Yahboom Controller iOS application built with **SwiftUI and MVVM architecture**.

## Prerequisites

- Mac with macOS 12.0 (Monterey) or later
- Xcode 14.0 or later
- iOS device running iOS 15.0+
- Apple Developer account (for device deployment)

## Important Note

**This app uses SwiftUI with MVVM architecture.** The Xcode project file (`.xcodeproj`) cannot be stored in Git as it's a binary format. You'll need to create the project manually and add the source files.

## Installation

### 1. Install Xcode

Download and install Xcode from the Mac App Store or [Apple Developer](https://developer.apple.com/xcode/).

### 2. Clone Repository

```bash
git clone https://github.com/tchdvz6sp2-png/yahboom-iphone-controller.git
cd yahboom-iphone-controller/ios
```

## Creating the Xcode Project

### Step-by-Step Project Creation

1. **Open Xcode**
   
2. **Create New Project**
   - File → New → Project
   - Select "iOS" → "App"
   - Click "Next"

3. **Configure Project**
   - **Product Name**: `YahboomController`
   - **Team**: Select your team
   - **Organization Identifier**: `com.yourname` (or your domain)
   - **Bundle Identifier**: Will be `com.yourname.YahboomController`
   - **Interface**: **SwiftUI** ⚠️ Important!
   - **Life Cycle**: **SwiftUI App** ⚠️ Important!
   - **Language**: **Swift**
   - **Use Core Data**: Unchecked
   - **Include Tests**: Optional

4. **Save Project**
   - Choose the `ios/YahboomController/` directory
   - Click "Create"

### Adding Source Files

After creating the project:

1. **Delete Default Files**
   - Delete `ContentView.swift` (we have our own views)
   
2. **Add ViewModels Folder**
   - Right-click on `YahboomController` in Project Navigator
   - New Group → Name it "ViewModels"
   - Drag these files into the group:
     - `ViewModels/RobotControlViewModel.swift`
     - `ViewModels/SettingsViewModel.swift`

3. **Add SwiftUIViews Folder**
   - Create new group "SwiftUIViews"
   - Drag these files into the group:
     - `SwiftUIViews/MainControlView.swift`
     - `SwiftUIViews/JoystickSwiftUIView.swift`
     - `SwiftUIViews/VideoPlayerSwiftUIView.swift`
     - `SwiftUIViews/DetectionOverlayView.swift`
     - `SwiftUIViews/SettingsView.swift`

4. **Add Models Folder**
   - Create new group "Models"
   - Drag these files into the group:
     - `Models/MotorController.swift`
     - `Models/YOLODetector.swift`
     - `Models/ConnectionManager.swift`
     - `Models/SSHManager.swift` (optional)

5. **Replace App Entry Point**
   - Delete the default `YahboomControllerApp.swift` file created by Xcode
   - Add the repository's `YahboomControllerApp.swift`

6. **Replace Info.plist**
   - Delete the default `Info.plist`
   - Add the repository's `Info.plist`
   - Or manually add the required privacy descriptions (see below)

## Project Configuration

### 1. Configure Info.plist

Add these privacy descriptions (or use the provided Info.plist):

```xml
<key>NSCameraUsageDescription</key>
<string>This app uses the camera for video processing and object detection.</string>

<key>NSLocalNetworkUsageDescription</key>
<string>This app requires local network access to control the Yahboom robot.</string>

<key>NSBonjourServices</key>
<array>
    <string>_rtsp._tcp</string>
</array>
```

### 2. Configure Signing & Capabilities

1. Select the project in the navigator
2. Select the "YahboomController" target
3. Go to "Signing & Capabilities" tab
4. **Automatically manage signing**: Checked
5. **Team**: Select your Apple Developer team
6. **Bundle Identifier**: Ensure it's unique (e.g., `com.yourname.YahboomController`)

### 3. Set Deployment Target

1. In project settings → General
2. **Minimum Deployments**: iOS 15.0

### 4. Required Capabilities

The app requires these capabilities (add if needed):

1. Click "+ Capability" in Signing & Capabilities
2. Add:
   - **Background Modes** (optional)
     - If added, enable "Audio, AirPlay, and Picture in Picture"

## YOLOv8 Integration

### Add YOLOv8 Model (Optional)

For object detection:

1. **Download Model**
   - Get YOLOv8 CoreML model: `yolov8n.mlmodel`
   - Sources: [Ultralytics](https://docs.ultralytics.com/), Apple Model Zoo

2. **Add to Project**
   - Drag `yolov8n.mlmodel` into Xcode project
   - Check "Copy items if needed"
   - Ensure "Target Membership" includes YahboomController
   - Click "Add"

3. **Verify Integration**
   - Click on the model file in Xcode
   - You should see model metadata and preview
   - Swift code is auto-generated

## Building the Application

### Build for Simulator

1. **Select Simulator**
   - From device menu, choose any iPhone simulator (iPhone 13, 14, etc.)
   
2. **Build**
   - Press ⌘+B or Product → Build
   
3. **Run**
   - Press ⌘+R or Product → Run
   - Note: Video streaming may not work in simulator

### Build for Device

1. **Connect Device**
   - Connect your iPhone/iPad via USB
   - Unlock the device
   - Trust the computer if prompted

2. **Select Device**
   - From device menu in Xcode, select your connected device

3. **Build and Run**
   - Press ⌘+R or Product → Run
   
4. **Trust Developer (First Time)**
   - On your device: Settings → General → VPN & Device Management
   - Tap on your developer certificate
   - Tap "Trust"

## Initial Configuration

### Configure Raspberry Pi Connection

On first launch:

1. **Tap Settings** (gear icon in top-right)

2. **Enter Connection Details**:
   - **IP Address**: Your Pi's IP (e.g., `192.168.1.100`)
   - **Motor Port**: UDP port (default: `5005`)
   - **RTSP URL**: Will auto-fill to `rtsp://192.168.1.100:8554/stream`
   - **Video Resolution**: Choose 720p for balanced performance

3. **Save Settings**
   - Tap "Save" in top-right
   - Settings are persisted to UserDefaults

4. **Connect to Robot**
   - Tap "Connect" button
   - Wait for green "Connected" indicator

### Verify Connection

Test each feature:
- ✅ **Video Stream**: Should display camera feed
- ✅ **Joystick**: Drag to control robot movement
- ✅ **Tracking**: Toggle to enable object detection
- ✅ **Emergency Stop**: Tap to halt motors

## Project Structure

```
ios/YahboomController/
├── YahboomController.xcodeproj  (created by you)
└── YahboomController/
    ├── YahboomControllerApp.swift   - SwiftUI App entry
    ├── Info.plist                    - App configuration
    │
    ├── ViewModels/                   - MVVM ViewModels
    │   ├── RobotControlViewModel.swift
    │   └── SettingsViewModel.swift
    │
    ├── SwiftUIViews/                 - SwiftUI Views
    │   ├── MainControlView.swift
    │   ├── JoystickSwiftUIView.swift
    │   ├── VideoPlayerSwiftUIView.swift
    │   ├── DetectionOverlayView.swift
    │   └── SettingsView.swift
    │
    ├── Models/                       - Business Logic
    │   ├── MotorController.swift
    │   ├── YOLODetector.swift
    │   ├── ConnectionManager.swift
    │   └── SSHManager.swift
    │
    ├── Assets.xcassets/              - Images, colors
    └── Preview Content/              - SwiftUI previews
```

## Features Overview

### Main Control View
- **Full-screen RTSP video** from Raspberry Pi camera
- **Joystick overlay** (bottom-left) for robot control
- **Object detection** with bounding boxes
- **Connection status** indicator (top)
- **Settings button** (top-right)
- **Emergency stop** button (bottom-right)

### Joystick Control
- **Touch-based** circular joystick
- **20Hz command rate** (sends every 50ms)
- **Differential drive** calculation
- **Visual feedback** with animated stick
- **Auto-center** on release

### Settings View
- **Raspberry Pi IP** configuration with validation
- **Motor port** setting (default: 5005)
- **RTSP URL** with auto-fill
- **Video resolution** picker
- **Connection management**
- **Persistent storage** via UserDefaults

### Object Detection
- **YOLOv8 CoreML** integration
- **Toggle on/off** in main view
- **Real-time processing** of video frames
- **Bounding boxes** with labels and confidence
- **On-device processing** (no cloud required)

### Emergency Stop
- **Manual trigger**: Red stop button
- **Auto-trigger**: Connection lost >1 second
- **Motor halt**: Stops all movement immediately
- **Visual indicator**: Alert message
- **Reset capability**: Orange reset button

## Development Tips

### Enable Debug Logging

In `MotorController.swift`:
```swift
motorController?.debugMode = true
```

View logs in Xcode console (⌘+⇧+C).

### SwiftUI Previews

Most views include SwiftUI previews:
```swift
#Preview {
    MainControlView()
}
```

Enable live previews: ⌥+⌘+↩ or Editor → Canvas

### Performance Optimization

For best performance:
- **Video**: Use 720p resolution for balance
- **Network**: Ensure strong Wi-Fi connection
- **Detection**: Disable if not needed (reduces CPU usage)
- **Battery**: Keep device charged during extended use

## Troubleshooting

### Build Errors

**"No such module 'SwiftUI'"**
- Solution: Ensure deployment target is iOS 15.0+

**"Cannot find type 'MainControlView'"**
- Solution: Ensure all SwiftUI view files are added to target

**"Signing requires a development team"**
- Solution: Select your team in Signing & Capabilities

### Runtime Issues

**Video stream not connecting**
- ✓ Check Pi's IP address is correct
- ✓ Verify RTSP server is running: `sudo systemctl status rtsp-server`
- ✓ Test with VLC: `vlc rtsp://192.168.1.100:8554/stream`
- ✓ Ensure devices are on same network
- ✓ Check firewall settings on Pi

**Motor control not responding**
- ✓ Verify UDP port is correct (default: 5005)
- ✓ Check motor_controller.py is running on Pi
- ✓ Test with: `python3 test_motors.py`
- ✓ Check for emergency stop active

**Object detection not working**
- ✓ Ensure YOLOv8 model is added to project
- ✓ Check model target membership
- ✓ Enable tracking toggle in app
- ✓ Check device supports CoreML (iPhone 7+, iPad Pro, etc.)

**Emergency stop won't reset**
- ✓ Ensure connection is active
- ✓ Check connection status indicator
- ✓ Try disconnecting and reconnecting

### Common Xcode Issues

**"Could not launch YahboomController"**
- Solution: Trust developer certificate on device (Settings → General → Device Management)

**Simulator shows black screen**
- Solution: This is expected - video requires actual device with network access

## Testing

### Manual Testing Checklist

- [ ] App launches successfully
- [ ] Settings page opens and saves correctly
- [ ] Connection to Pi succeeds
- [ ] Video stream displays
- [ ] Joystick controls robot smoothly
- [ ] Emergency stop works (manual and auto)
- [ ] Object detection shows bounding boxes
- [ ] Settings persist after app restart
- [ ] Video auto-reconnects on interruption

### Performance Testing

Monitor in Xcode:
- **CPU Usage**: Should be <30% in normal operation
- **Memory**: Should be <100MB
- **Network**: Check for smooth streaming
- **Battery**: Monitor for excessive drain

## Deployment

### TestFlight Distribution

1. **Archive the App**
   - Product → Archive
   - Wait for archiving to complete

2. **Upload to App Store Connect**
   - Window → Organizer
   - Select archive → "Distribute App"
   - Choose "App Store Connect"
   - Follow prompts

3. **Configure TestFlight**
   - Log into [App Store Connect](https://appstoreconnect.apple.com/)
   - Select your app
   - Go to TestFlight tab
   - Add testers
   - Submit for beta review

4. **Share with Testers**
   - Once approved, testers receive email
   - They can install via TestFlight app

### Ad-Hoc Distribution

For limited device testing:

1. **Archive the App**
2. **Export with Ad-Hoc**
   - Organizer → Distribute App → Ad-Hoc
   - Select devices (must be registered in developer portal)
   - Export

3. **Install on Devices**
   - Use Xcode Devices window
   - Or use Apple Configurator 2

## Next Steps

### Customization
- Change app icon and launch screen
- Customize colors in `Assets.xcassets`
- Add haptic feedback
- Implement gesture controls

### Advanced Features
- Add telemetry display (speed, battery, sensors)
- Implement video recording
- Add multiple robot profiles
- Create autonomous navigation modes
- Integrate ARKit for spatial controls

### Optimization
- Profile with Instruments
- Optimize video codec settings
- Reduce network latency
- Improve object detection performance

## Resources

- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Combine Framework](https://developer.apple.com/documentation/combine)
- [CoreML Documentation](https://developer.apple.com/documentation/coreml)
- [AVFoundation Guide](https://developer.apple.com/documentation/avfoundation)
- [YOLOv8 Documentation](https://docs.ultralytics.com/)
- [Project GitHub Repo](https://github.com/tchdvz6sp2-png/yahboom-iphone-controller)

## Support

For issues:
1. Check [TROUBLESHOOTING.md](../docs/TROUBLESHOOTING.md)
2. Review [SwiftUI_README.md](SwiftUI_README.md)
3. Check existing GitHub issues
4. Create new issue with:
   - iOS version
   - Xcode version
   - Error messages
   - Steps to reproduce

