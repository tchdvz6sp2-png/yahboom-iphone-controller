# Yahboom Controller iOS App

This directory contains the iOS application for controlling the Yahboom Rider Pi CM4 balancing robot.

## ⚠️ Important: SwiftUI MVVM Implementation

This app has been fully implemented using **SwiftUI with MVVM architecture** as specified. The legacy UIKit files are retained for reference but the app now runs entirely on SwiftUI.

**See [SwiftUI_README.md](SwiftUI_README.md) for complete implementation details.**

## Quick Start

Since Xcode projects are binary files that can't be stored in Git, follow these steps:

### 1. Create Xcode Project

```bash
# Open Xcode and create a new project:
# - iOS App
# - Interface: SwiftUI
# - Life Cycle: SwiftUI App
# - Language: Swift
# - Name: YahboomController
# - Bundle ID: com.yourname.yahboomcontroller
```

### 2. Add Source Files to Project

After creating the project, add these files to your Xcode project:

**Required Files (SwiftUI MVVM):**
```
YahboomController/
├── YahboomControllerApp.swift      ← Replace the default one
├── ViewModels/
│   ├── RobotControlViewModel.swift
│   └── SettingsViewModel.swift
├── SwiftUIViews/
│   ├── MainControlView.swift
│   ├── JoystickSwiftUIView.swift
│   ├── VideoPlayerSwiftUIView.swift
│   ├── DetectionOverlayView.swift
│   └── SettingsView.swift
├── Models/
│   ├── MotorController.swift
│   ├── YOLODetector.swift
│   └── ConnectionManager.swift
└── Info.plist                      ← Replace the default one
```

**Optional Files (Legacy UIKit - for reference):**
- `ViewControllers/` - Original UIKit view controllers
- `Views/` - Original UIKit custom views
- `AppDelegate.swift` - Legacy app delegate
- `SceneDelegate.swift` - Legacy scene delegate

### 3. Configure Project Settings

1. **Signing & Capabilities:**
   - Select your development team
   - Choose unique bundle identifier

2. **Info.plist Settings:**
   - Already configured in the provided Info.plist
   - Includes camera, local network permissions
   - Configured for SwiftUI lifecycle

3. **Deployment Target:**
   - Set to iOS 15.0 or later

### 4. Add YOLOv8 Model (Optional)

For object detection:
1. Download YOLOv8 CoreML model: `yolov8n.mlmodel`
2. Drag into Xcode project
3. Ensure target membership is checked

## Features Implemented

✅ **1. Joystick Control**
- SwiftUI-based touch joystick
- 20Hz command rate (50ms intervals)
- Differential drive calculation
- Visual feedback

✅ **2. RTSP Video Streaming**
- AVFoundation-based player
- Auto-reconnection on failure
- Low-latency display
- Frame extraction for detection

✅ **3. YOLOv8 Object Tracking**
- CoreML integration
- Toggle enable/disable
- Bounding box overlay
- Real-time processing

✅ **4. Settings Page**
- IP address configuration
- UDP port setting
- RTSP URL
- Video resolution options
- UserDefaults persistence
- Input validation

✅ **5. Emergency Stop**
- Manual trigger button
- Auto-trigger on 1s connection loss
- Visual indicators
- Motor halt

✅ **6. MVVM Architecture**
- ViewModels for state management
- Models for business logic
- SwiftUI Views for UI
- Reactive with Combine

## Project Structure

```
YahboomController/
├── YahboomController/
│   ├── YahboomControllerApp.swift  - SwiftUI App entry point
│   ├── Info.plist                  - App configuration
│   │
│   ├── ViewModels/                 - MVVM ViewModels
│   │   ├── RobotControlViewModel.swift
│   │   └── SettingsViewModel.swift
│   │
│   ├── SwiftUIViews/               - SwiftUI Views
│   │   ├── MainControlView.swift
│   │   ├── JoystickSwiftUIView.swift
│   │   ├── VideoPlayerSwiftUIView.swift
│   │   ├── DetectionOverlayView.swift
│   │   └── SettingsView.swift
│   │
│   ├── Models/                     - Business Logic
│   │   ├── MotorController.swift   - UDP motor control
│   │   ├── YOLODetector.swift      - CoreML detection
│   │   ├── ConnectionManager.swift - Connection handling
│   │   └── SSHManager.swift        - SSH placeholder
│   │
│   ├── ViewControllers/            - Legacy UIKit (reference)
│   │   ├── MainViewController.swift
│   │   ├── SettingsViewController.swift
│   │   └── StreamViewController.swift
│   │
│   ├── Views/                      - Legacy UIKit (reference)
│   │   ├── JoystickView.swift
│   │   └── VideoPlayerView.swift
│   │
│   └── AppDelegate.swift           - Legacy (reference)
│   └── SceneDelegate.swift         - Legacy (reference)
│
└── README.md (this file)
```

## Building the Project

### From Scratch

1. **Create Project in Xcode:**
   ```
   File → New → Project
   iOS → App
   Interface: SwiftUI
   Life Cycle: SwiftUI App
   ```

2. **Add Files:**
   - Delete default `ContentView.swift`
   - Add all files from repository
   - Ensure proper target membership

3. **Configure Info.plist:**
   - Replace with provided Info.plist
   - Or manually add privacy descriptions

4. **Build:**
   ```
   Product → Build (⌘+B)
   ```

5. **Run on Device:**
   ```
   Product → Run (⌘+R)
   ```

### Command Line (Advanced)

While Xcode projects are typically managed via GUI, you can use `xcodebuild`:

```bash
# After creating the project manually
xcodebuild -project YahboomController.xcodeproj \
           -scheme YahboomController \
           -destination 'platform=iOS,name=Your iPhone' \
           build
```

## Required Capabilities

Enable in Xcode → Signing & Capabilities:

- [x] **Local Network** - For UDP communication with Pi
- [x] **Background Modes** (optional) - For maintaining connections

Privacy Descriptions (in Info.plist):
- [x] `NSCameraUsageDescription` - For video processing
- [x] `NSLocalNetworkUsageDescription` - For robot communication
- [x] `NSBonjourServices` - For RTSP streaming

## Dependencies

**None!** This project uses only iOS system frameworks:
- SwiftUI
- Combine  
- UIKit (for video player wrapper)
- AVFoundation
- CoreML
- Vision
- Network

No CocoaPods, SPM, or Carthage required.

## Configuration

On first launch:

1. **Open Settings** (gear icon)
2. **Enter Raspberry Pi IP**: `192.168.1.100`
3. **Enter Motor Port**: `5005` (default)
4. **RTSP URL**: Auto-fills to `rtsp://192.168.1.100:8554/stream`
5. **Tap Connect**

Settings are persisted using `UserDefaults`.

## Usage

### Main Screen

- **Video Stream**: Full-screen RTSP feed
- **Joystick** (bottom-left): Touch control for movement
- **Tracking Toggle** (top-right): Enable/disable object detection
- **Settings** (top-right): Gear icon
- **Emergency Stop** (bottom-right): Red stop button

### Joystick Control

- **Drag up**: Move forward
- **Drag down**: Move backward
- **Drag left/right**: Turn
- **Release**: Stop motors

### Object Detection

1. Add `yolov8n.mlmodel` to project
2. Tap "Tracking Off" to enable
3. Green boxes appear around detected objects
4. Shows label and confidence %

### Emergency Stop

- **Manual**: Tap red STOP button
- **Automatic**: Triggered if connection lost >1s
- **Reset**: Tap orange RESET button

## Testing

### Manual Testing

- [ ] Joystick responds smoothly
- [ ] Commands sent at 20Hz
- [ ] Video displays and auto-reconnects
- [ ] Object detection works
- [ ] Settings persist
- [ ] Emergency stop works
- [ ] Auto-stop on connection loss

### Debug Mode

Enable in `RobotControlViewModel.swift`:
```swift
motorController?.debugMode = true
```

View logs in Xcode console.

## Troubleshooting

See the main [TROUBLESHOOTING.md](../docs/TROUBLESHOOTING.md) guide.

### Common Issues

**Video not displaying:**
- Verify RTSP URL is correct
- Check Pi is streaming
- Same network required

**Connection failed:**
- Verify IP address
- Check UDP port is open
- Ensure motor controller running on Pi

**Object detection not working:**
- Add YOLOv8 model to project
- Check target membership
- Enable tracking toggle

## Architecture Details

### MVVM Pattern

```
View (SwiftUI) ←→ ViewModel (@Published) ←→ Model (Business Logic)
     ↓                      ↓                         ↓
  UI Events          State Management            Network/Hardware
```

### Data Flow

1. User interacts with View
2. View calls ViewModel method
3. ViewModel updates Model
4. Model performs action
5. ViewModel updates @Published properties
6. View automatically re-renders

### Key Components

- **RobotControlViewModel**: Main state machine
  - Connection state
  - Joystick commands (20Hz)
  - Emergency stop logic
  - Video frame processing
  
- **SettingsViewModel**: Configuration management
  - Input validation
  - Persistent storage
  - Settings retrieval

## Performance

- Joystick: 20Hz (50ms intervals)
- Video: 30 FPS (when available)
- Detection: Real-time on frames
- Connection Monitor: 10Hz (100ms checks)

## Development

### Adding Features

1. **New Setting**: Add to `SettingsViewModel`
2. **New View**: Create in `SwiftUIViews/`
3. **New Logic**: Add to `RobotControlViewModel` or create new ViewModel
4. **New Model**: Add to `Models/`

### Best Practices

- Use `@Published` for observable state
- Keep Views lightweight
- Business logic in ViewModels
- Network/hardware in Models
- Follow SwiftUI lifecycle

## Documentation

- **[SwiftUI_README.md](SwiftUI_README.md)** - Detailed SwiftUI implementation guide
- **[ARCHITECTURE.md](../docs/ARCHITECTURE.md)** - Overall system architecture
- **[SETUP_IOS.md](../docs/SETUP_IOS.md)** - Detailed iOS setup
- **[TROUBLESHOOTING.md](../docs/TROUBLESHOOTING.md)** - Common issues

## Version History

- **v1.0** - SwiftUI MVVM implementation
  - Full SwiftUI interface
  - MVVM architecture
  - 20Hz joystick control
  - Auto-reconnecting video
  - YOLOv8 object detection
  - Emergency stop with timeout
  - Persistent settings

## License

This project is provided as-is for educational and research purposes.

