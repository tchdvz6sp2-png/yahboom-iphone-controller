# Quick Start Checklist

This checklist helps you get the iOS app running on your device.

## Prerequisites

- [ ] Mac with macOS 12.0+ 
- [ ] Xcode 14.0+ installed
- [ ] iOS device running iOS 15.0+
- [ ] Apple Developer account (free or paid)
- [ ] Raspberry Pi with robot set up and running

## Step 1: Create Xcode Project

- [ ] Open Xcode
- [ ] File → New → Project
- [ ] Select: iOS → App
- [ ] Configure:
  - [ ] Product Name: `YahboomController`
  - [ ] Interface: **SwiftUI** (Important!)
  - [ ] Life Cycle: **SwiftUI App** (Important!)
  - [ ] Language: Swift
- [ ] Save to: `ios/YahboomController/` directory

## Step 2: Add Source Files

- [ ] Delete default `ContentView.swift` file
- [ ] Create group: `ViewModels`
  - [ ] Add: `ViewModels/RobotControlViewModel.swift`
  - [ ] Add: `ViewModels/SettingsViewModel.swift`
- [ ] Create group: `SwiftUIViews`
  - [ ] Add: `SwiftUIViews/MainControlView.swift`
  - [ ] Add: `SwiftUIViews/JoystickSwiftUIView.swift`
  - [ ] Add: `SwiftUIViews/VideoPlayerSwiftUIView.swift`
  - [ ] Add: `SwiftUIViews/DetectionOverlayView.swift`
  - [ ] Add: `SwiftUIViews/SettingsView.swift`
- [ ] Create group: `Models`
  - [ ] Add: `Models/MotorController.swift`
  - [ ] Add: `Models/YOLODetector.swift`
  - [ ] Add: `Models/ConnectionManager.swift`
  - [ ] Add: `Models/SSHManager.swift` (optional)
- [ ] Replace: `YahboomControllerApp.swift`
- [ ] Replace: `Info.plist`

**Ensure all files have target membership checked!**

## Step 3: Configure Project

- [ ] Select project in Navigator
- [ ] Select `YahboomController` target
- [ ] General tab:
  - [ ] Minimum Deployments: iOS 15.0
- [ ] Signing & Capabilities tab:
  - [ ] Automatically manage signing: ✓
  - [ ] Team: [Select your team]
  - [ ] Bundle Identifier: `com.yourname.YahboomController`

## Step 4: Add YOLOv8 Model (Optional)

For object detection:
- [ ] Download `yolov8n.mlmodel` (see `docs/YOLO_INTEGRATION.md`)
- [ ] Drag model into Xcode project
- [ ] Check: "Copy items if needed"
- [ ] Check: Target membership for YahboomController
- [ ] Click model file, verify metadata displays

## Step 5: Build Project

- [ ] Select iPhone Simulator or your device
- [ ] Product → Build (⌘+B)
- [ ] Fix any errors (should build cleanly)

## Step 6: Run on Device

- [ ] Connect iOS device via USB
- [ ] Select device from device menu
- [ ] Product → Run (⌘+R)
- [ ] On device: Trust developer certificate if prompted
  - [ ] Settings → General → VPN & Device Management
  - [ ] Tap your certificate → Trust

## Step 7: Configure Robot Connection

- [ ] App launches successfully
- [ ] Tap Settings (gear icon, top-right)
- [ ] Enter your Raspberry Pi details:
  - [ ] IP Address: `_____._____._____.______`
  - [ ] Motor Port: `5005` (or your custom port)
  - [ ] RTSP URL: Auto-fills or enter manually
  - [ ] Video Resolution: Choose 720p
- [ ] Tap "Save"
- [ ] Tap "Connect"

## Step 8: Test Features

### Video Stream
- [ ] Video displays from Pi camera
- [ ] Stream is smooth (30 FPS)
- [ ] If interrupted, reconnects automatically

### Joystick Control
- [ ] Drag joystick (bottom-left)
- [ ] Robot moves forward/backward
- [ ] Robot turns left/right
- [ ] Release joystick, robot stops

### Object Detection (if model added)
- [ ] Tap "Tracking Off" (top-right)
- [ ] Button turns green: "Tracking On"
- [ ] Green bounding boxes appear around objects
- [ ] Labels show object class and confidence %

### Emergency Stop
- [ ] Tap red STOP button (bottom-right)
- [ ] Robot stops immediately
- [ ] "EMERGENCY STOP ACTIVE" message displays
- [ ] Joystick is disabled
- [ ] Tap orange RESET button
- [ ] Normal operation resumes

### Connection Timeout
- [ ] With robot connected, unplug Pi network
- [ ] Wait 1-2 seconds
- [ ] Emergency stop should auto-trigger
- [ ] Status shows "Connection Lost - Emergency Stop"

### Settings Persistence
- [ ] Configure settings
- [ ] Close app completely
- [ ] Relaunch app
- [ ] Settings are remembered

## Troubleshooting

### Build Errors

**"No such module 'SwiftUI'"**
- Solution: Set deployment target to iOS 15.0+

**"Cannot find type 'MainControlView'"**
- Solution: Ensure all SwiftUI files have target membership checked

**"Signing requires a development team"**
- Solution: Select your team in Signing & Capabilities

### Runtime Errors

**Video not displaying**
- [ ] Verify Pi IP address is correct
- [ ] Check RTSP server is running on Pi: `sudo systemctl status rtsp-server`
- [ ] Test with VLC: `vlc rtsp://[pi-ip]:8554/stream`
- [ ] Ensure iOS device and Pi are on same network

**Motors not responding**
- [ ] Check motor_controller.py is running on Pi
- [ ] Verify UDP port is correct (default: 5005)
- [ ] Test with: `python3 test_motors.py` on Pi
- [ ] Check for emergency stop active

**Object detection not working**
- [ ] Ensure YOLOv8 model is added to project
- [ ] Check model has target membership
- [ ] Enable tracking toggle
- [ ] Check console for error messages

## Performance Notes

- CPU usage should be 25-40% during normal operation
- Memory usage should be <150 MB
- Video should maintain 30 FPS
- Joystick should respond instantly

## Success Criteria

✓ App builds without errors  
✓ Runs on physical iOS device  
✓ Connects to Raspberry Pi  
✓ Video stream displays smoothly  
✓ Joystick controls robot movement  
✓ Emergency stop works (manual and auto)  
✓ Settings persist after restart  
✓ (Optional) Object detection shows bounding boxes  

## Need Help?

- Read: `ios/README.md` - Overview and features
- Read: `ios/SwiftUI_README.md` - Implementation details
- Read: `docs/SETUP_IOS.md` - Detailed setup instructions
- Read: `docs/YOLO_INTEGRATION.md` - Object detection setup
- Read: `docs/TROUBLESHOOTING.md` - Common issues
- Check: Xcode console for error messages

## Next Steps

After successful testing:
- Customize UI colors and branding
- Add additional features
- Optimize for your robot configuration
- Share with TestFlight for beta testing
- Submit to App Store (optional)

---

**Status after completion**: iOS app is fully functional and controlling your Yahboom robot! 🎉
