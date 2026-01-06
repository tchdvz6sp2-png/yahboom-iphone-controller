# Yahboom Controller iOS App - SwiftUI MVVM Implementation

This iOS application provides complete control of the Yahboom Rider Pi CM4 balancing robot using SwiftUI and MVVM architecture.

## Architecture

The app follows **MVVM (Model-View-ViewModel)** architecture with clear separation of concerns:

### Models
- `MotorController.swift` - UDP-based motor control
- `YOLODetector.swift` - CoreML object detection wrapper
- `ConnectionManager.swift` - Legacy connection management (retained for compatibility)
- `SSHManager.swift` - SSH connectivity (placeholder)

### ViewModels
- `RobotControlViewModel.swift` - Main state management for robot control
  - Handles connection state
  - Manages joystick commands at 20Hz
  - Processes video frames for object detection
  - Emergency stop logic with 1-second timeout
  
- `SettingsViewModel.swift` - Settings management with validation
  - IP address validation
  - Port validation
  - RTSP URL validation
  - Persistent storage via UserDefaults

### Views (SwiftUI)
- `MainControlView.swift` - Main control interface
- `JoystickSwiftUIView.swift` - Touch-based joystick control
- `VideoPlayerSwiftUIView.swift` - RTSP video player with frame extraction
- `DetectionOverlayView.swift` - Bounding box overlay for detected objects
- `SettingsView.swift` - Configuration interface

## Features

### ✅ 1. Joystick Control
- **SwiftUI-based** touch control overlay
- Sends movement commands at **20Hz** (50ms intervals)
- Directional control (x: -1 to 1, y: -1 to 1)
- Speed-based differential drive calculation
- Visual feedback with animated stick

### ✅ 2. RTSP Video Streaming
- **AVFoundation-based** RTSP player
- Low-latency video display
- **Auto-reconnection** on stream interruption (2-second delay)
- Handles playback stalls automatically
- Frame extraction for object detection

### ✅ 3. Object Tracking with YOLOv8
- **CoreML integration** for YOLOv8 models
- Toggle button to enable/disable tracking
- **Bounding box overlay** on detected objects
- Shows label and confidence percentage
- Processes video frames in real-time

### ✅ 4. Settings Page
- **Persistent storage** using UserDefaults
- Adjustable settings:
  - Raspberry Pi IP address
  - UDP motor control port (default: 5005)
  - RTSP URL
  - Video resolution (480p, 720p, 1080p)
- Input validation with error messages
- Auto-fill RTSP URL from IP address

### ✅ 5. Emergency Stop
- **Manual trigger** via red stop button
- **Automatic trigger** on connection loss >1 second
- Stops all motor commands immediately
- Visual indicator when active
- Reset button to resume operation
- Disables joystick when active

### ✅ 6. MVVM Architecture
- **Models**: Data and business logic
- **ViewModels**: State management with `@Published` properties
- **Views**: SwiftUI declarative UI
- Proper separation of concerns
- Reactive programming with Combine

## Requirements

- **iOS 15.0+**
- Swift 5.0+
- SwiftUI
- Xcode 14.0+

## Project Structure

```
YahboomController/
├── YahboomControllerApp.swift     - SwiftUI App entry point
├── AppDelegate.swift               - Legacy app delegate
├── ViewModels/
│   ├── RobotControlViewModel.swift - Main control logic
│   └── SettingsViewModel.swift     - Settings management
├── SwiftUIViews/
│   ├── MainControlView.swift       - Main interface
│   ├── JoystickSwiftUIView.swift   - Joystick control
│   ├── VideoPlayerSwiftUIView.swift - Video player
│   ├── DetectionOverlayView.swift  - Object detection overlay
│   └── SettingsView.swift          - Settings UI
├── Models/
│   ├── MotorController.swift       - UDP motor control
│   ├── YOLODetector.swift          - CoreML detection
│   ├── ConnectionManager.swift     - Connection handling
│   └── SSHManager.swift            - SSH placeholder
├── ViewControllers/                - Legacy UIKit (retained)
├── Views/                          - Legacy UIKit (retained)
└── Info.plist                      - App configuration
```

## Setup Instructions

### 1. Open in Xcode

Since Xcode projects are binary files, you'll need to create the project:

1. Open Xcode
2. Create new **iOS App** project
3. Name: "YahboomController"
4. Interface: **SwiftUI**
5. Life Cycle: **SwiftUI App**
6. Language: **Swift**

### 2. Add Source Files

Add all files from the repository to your Xcode project:
- Drag the `ViewModels/` folder into the project
- Drag the `SwiftUIViews/` folder into the project
- Drag the `Models/` folder into the project
- Replace `YahboomControllerApp.swift` with the repository version
- Replace `Info.plist` with the repository version

### 3. Configure Signing

1. Select your project in Xcode
2. Go to **Signing & Capabilities**
3. Select your development team
4. Choose a unique bundle identifier

### 4. Add Capabilities

Enable these capabilities:
- **Local Network** (for UDP communication)
- **Background Modes** (optional, for maintaining connections)

### 5. Add Privacy Descriptions

The Info.plist already includes:
- `NSCameraUsageDescription` - For video processing
- `NSLocalNetworkUsageDescription` - For robot control
- `NSBonjourServices` - For RTSP streaming

### 6. Add YOLOv8 Model (Optional)

To enable object detection:
1. Download a YOLOv8 CoreML model (e.g., `yolov8n.mlmodel`)
2. Drag it into your Xcode project
3. Ensure "Target Membership" includes YahboomController
4. The app will automatically load and use it

## Usage

### First Time Setup

1. Launch the app on your iOS device
2. Tap the **Settings** gear icon
3. Enter your Raspberry Pi's IP address (e.g., `192.168.1.100`)
4. Enter the motor control port (default: `5005`)
5. RTSP URL will auto-fill or enter manually
6. Tap **Connect**

### Controlling the Robot

1. Use the **joystick** (bottom-left) to control movement:
   - Drag up/down for forward/backward
   - Drag left/right for turning
   - Release to stop

2. Toggle **object tracking** (top-right):
   - Tap "Tracking Off" to enable
   - Green boxes will appear around detected objects

3. **Emergency stop** (bottom-right):
   - Tap red STOP button to halt immediately
   - Tap orange RESET button to resume

### Connection Monitoring

- **Green indicator**: Connected
- **Red indicator**: Disconnected
- **Automatic emergency stop** if connection lost >1 second

## Technical Details

### Joystick Update Rate

The joystick sends commands at exactly **20Hz**:
```swift
Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { ... }
```

### Emergency Stop Logic

Monitors connection with 100ms checks:
```swift
Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { ... }
if timeSinceLastCommand > 1.0 {
    triggerEmergencyStop()
}
```

### Video Auto-Reconnection

Automatically reconnects on errors:
```swift
DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
    self?.startStream(url: url)
}
```

### MVVM Data Flow

```
User Action → View → ViewModel (@Published) → Model → Network/Hardware
                ↑                    ↓
                └──── State Update ──┘
```

## Testing

### Manual Testing Checklist

- [ ] Joystick responds smoothly
- [ ] Commands sent at 20Hz (check logs)
- [ ] Video stream displays
- [ ] Video reconnects on interruption
- [ ] Object detection shows bounding boxes
- [ ] Settings persist after app restart
- [ ] Emergency stop halts motors
- [ ] Auto-stop on connection loss
- [ ] Settings validation works

### Debug Logging

Enable debug mode in `MotorController`:
```swift
motorController?.debugMode = true
```

## Troubleshooting

### Video Not Displaying

1. Check RTSP URL is correct
2. Verify Raspberry Pi is streaming
3. Ensure you're on the same network
4. Check firewall settings

### Connection Failed

1. Verify IP address is correct
2. Ping Raspberry Pi: `ping 192.168.1.100`
3. Check UDP port is open (default: 5005)
4. Ensure motor controller is running on Pi

### Object Detection Not Working

1. Ensure YOLOv8 model is added to project
2. Check model file is named correctly
3. Verify model is included in target
4. Enable tracking with toggle button

## Performance

- **Joystick**: 20Hz (50ms intervals)
- **Video**: 30 FPS (when available)
- **Detection**: Real-time on available frames
- **Connection Monitor**: 10Hz (100ms checks)

## Future Enhancements

- [ ] Telemetry display (speed, battery, etc.)
- [ ] Recording video to device
- [ ] Multiple robot support
- [ ] Gesture-based controls
- [ ] ARKit integration for spatial control

## License

This project is provided as-is for educational purposes.
