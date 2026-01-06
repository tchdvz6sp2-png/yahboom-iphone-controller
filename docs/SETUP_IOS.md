# iOS Application Setup Guide

Complete guide for building, deploying, and using the Yahboom Controller iOS application.

## 📋 Prerequisites

### Hardware Requirements
- **Mac** running macOS 12.0 (Monterey) or later
- **iPhone** running iOS 15.0 or later
  - Optimized for iPhone 12
  - Should work on iPhone 11 and later
- **USB cable** for device connection (first deployment)

### Software Requirements
- **Xcode 14.0 or later**
  - Download from the Mac App Store
  - Includes Swift 5.7+ and SwiftUI
- **Apple Developer Account**
  - Free account for personal development
  - Paid account ($99/year) for App Store distribution
- **Git** (usually pre-installed on macOS)

### Network Requirements
- iPhone and Raspberry Pi must be on the **same WiFi network**
- Or iPhone has network access to the Raspberry Pi's IP address
- Stable WiFi connection (5GHz recommended for lower latency)

## 🛠️ Installation

### Step 1: Clone the Repository

```bash
# Open Terminal
git clone https://github.com/tchdvz6sp2-png/yahboom-iphone-controller.git
cd yahboom-iphone-controller/ios/YahboomController
```

### Step 2: Open the Project in Xcode

```bash
# Option 1: From Terminal
open YahboomController.xcodeproj

# Option 2: From Finder
# Navigate to ios/YahboomController and double-click YahboomController.xcodeproj
```

### Step 3: Configure Signing & Capabilities

1. **Select the project** in the Project Navigator (left sidebar)
2. **Select the target** "YahboomController"
3. **Go to "Signing & Capabilities" tab**
4. **Configure Team**:
   - Click on "Team" dropdown
   - Select your Apple ID / Team
   - If not logged in, click "Add Account" and sign in with your Apple ID
5. **Bundle Identifier**:
   - Xcode may automatically update it to be unique
   - Note: You may need to change it if there's a conflict

### Step 4: Configure the Project for Your Device

1. **Connect your iPhone** to your Mac via USB
2. **Trust the computer** on iPhone (if prompted)
3. **Select your iPhone** as the build target:
   - Click on the scheme selector (top-left, next to Play button)
   - Choose your iPhone from the list
4. **Build the project** (Cmd+B) to verify everything compiles

### Step 5: Deploy to iPhone

1. **Click the Run button** (Play icon) or press **Cmd+R**
2. **Wait for the build** to complete
3. **Trust the developer** on iPhone (first time only):
   - Go to Settings → General → VPN & Device Management
   - Tap on your developer account
   - Tap "Trust [Your Account]"
4. **Launch the app** from your iPhone home screen

## ⚙️ Configuration

### Initial App Configuration

When you first launch the app:

1. **Tap the Settings icon** (gear icon in top-right)
2. **Configure Robot Connection**:
   ```
   Robot IP Address: 192.168.1.100  (your Pi's IP)
   SSH Port: 22
   SSH Username: pi
   SSH Password: [your password]
   ```
3. **Configure RTSP Stream**:
   ```
   RTSP URL: rtsp://192.168.1.100:8554/stream
   ```
4. **Configure Motor Control**:
   ```
   UDP Port: 5000
   Control Update Rate: 20 Hz
   ```
5. **Person Tracking Settings**:
   ```
   Enable Tracking: OFF (toggle to ON when ready)
   Confidence Threshold: 0.5
   Tracking Speed: Medium
   ```

### Obtaining Your Raspberry Pi's IP Address

On the Raspberry Pi, run:
```bash
hostname -I
```
Use the first IP address shown.

## 📱 Using the App

### Main Screen

The main screen displays:
- **Video stream** from the robot (top 2/3 of screen)
- **Connection status** indicator (top-left)
- **Settings button** (top-right)
- **Joystick control** (bottom 1/3 of screen)

### Connecting to the Robot

1. **Ensure the Raspberry Pi** is running:
   - RTSP server: `python3 rtsp_server.py`
   - Motor controller: `python3 motor_controller.py`
2. **Tap the "Connect" button** in the app
3. **Wait for connection** (usually 2-5 seconds)
4. **Green indicator** shows successful connection
5. **Video stream** should start automatically

### Manual Control with Joystick

1. **Touch and drag** the joystick at the bottom of the screen
2. **Up/Down** controls forward/backward movement
3. **Left/Right** controls turning
4. **Release** to stop movement
5. **Center circle** shows current position

### Person Tracking Mode

1. **Enable in Settings**: Toggle "Enable Tracking" to ON
2. **Return to main screen**: Tracking starts automatically
3. **Detection box** appears around detected persons
4. **Robot follows** the detected person automatically
5. **Manual override**: Use joystick to override tracking temporarily

### Emergency Stop

The app includes automatic emergency stop:
- **Connection loss**: Motors stop immediately if connection drops
- **Manual stop**: Tap anywhere outside joystick to stop
- **Timeout**: Motors stop if no command received for 1 second

## 🏗️ Building for Distribution

### Debug Build (Development)

```bash
cd ios/YahboomController
xcodebuild -scheme YahboomController -configuration Debug
```

### Release Build (Optimized)

```bash
xcodebuild -scheme YahboomController -configuration Release \
  -archivePath YahboomController.xcarchive archive

xcodebuild -exportArchive \
  -archivePath YahboomController.xcarchive \
  -exportPath ./build \
  -exportOptionsPlist ExportOptions.plist
```

### TestFlight Distribution

1. **Archive the app** in Xcode:
   - Product → Archive
2. **Upload to App Store Connect**:
   - Window → Organizer
   - Select the archive
   - Click "Distribute App"
   - Follow the prompts

## 🔧 Advanced Configuration

### YOLOv8 Model

The app includes a pre-trained YOLOv8n CoreML model. To use a custom model:

1. **Train your model** using Ultralytics YOLOv8
2. **Export to CoreML**:
   ```python
   from ultralytics import YOLO
   model = YOLO('your-model.pt')
   model.export(format='coreml')
   ```
3. **Replace the model**:
   - Add your `.mlmodel` file to the Xcode project
   - Update the model name in `PersonTracker.swift`

### Network Optimization

For best performance:
- Use **5GHz WiFi** (lower latency than 2.4GHz)
- Ensure **strong signal** (-50 dBm or better)
- **Minimize other network traffic** during use
- Consider using **direct WiFi connection** to Pi (Pi as access point)

### Video Quality Settings

Edit `config.yaml` on Raspberry Pi to adjust:
```yaml
rtsp:
  resolution: "640x480"  # Lower for better latency
  framerate: 30
  bitrate: 2000000       # 2 Mbps
```

## 🐛 Troubleshooting

### App won't install on iPhone

**Problem**: "Untrusted Developer" message
**Solution**: 
1. Settings → General → VPN & Device Management
2. Tap your developer account
3. Tap "Trust"

### Video stream not showing

**Problem**: Black screen or "No Stream" message
**Solution**:
1. Verify RTSP server is running on Pi
2. Check RTSP URL in Settings
3. Verify network connectivity
4. Check Pi's camera: `libcamera-hello`

### Joystick not responding

**Problem**: Touch input not registering
**Solution**:
1. Check connection status (must be connected)
2. Verify motor controller is running on Pi
3. Check UDP port in Settings matches Pi config
4. Try restarting the app

### Person tracking not working

**Problem**: No detection boxes appearing
**Solution**:
1. Ensure "Enable Tracking" is ON in Settings
2. Verify good lighting conditions
3. Check confidence threshold (lower = more detections)
4. Ensure person is visible in frame
5. Check iPhone has sufficient processing power

### Connection keeps dropping

**Problem**: Frequent disconnections
**Solution**:
1. Check WiFi signal strength
2. Move closer to WiFi router
3. Reduce interference (other devices)
4. Check Pi's SSH server is stable
5. Increase timeout in Settings

### High video latency

**Problem**: Significant delay in video
**Solution**:
1. Switch to 5GHz WiFi
2. Reduce video resolution on Pi
3. Lower bitrate in Pi config
4. Close other apps on iPhone
5. Check network bandwidth

## 📊 Performance Tips

### Optimizing for iPhone 12

The app is optimized for iPhone 12:
- **Person tracking** runs at 15-30 FPS
- **Video latency** typically 80-120ms
- **Control response** under 50ms

### Battery Life

For longer runtime:
- **Lower screen brightness**
- **Disable person tracking** when not needed
- **Close background apps**
- **Use Low Power Mode** (may reduce tracking FPS)

## 🔐 Security Best Practices

### Credential Storage

- **Never hardcode** passwords in the app
- **Use Keychain** for credential storage (already implemented)
- **Change default** Pi password
- **Use strong passwords** (12+ characters)

### Network Security

- **Use WPA3** WiFi if available
- **Change default** SSH port (not 22)
- **Disable** SSH password auth, use keys instead
- **Firewall** on Pi to restrict access

## 📝 Development Notes

### Project Structure

```
YahboomController/
├── Models/                    # Data models
│   ├── RobotSettings.swift   # Settings model
│   └── MotorCommand.swift    # Motor command model
├── ViewModels/               # Business logic
│   ├── ConnectionViewModel.swift
│   ├── StreamViewModel.swift
│   └── ControlViewModel.swift
├── Views/                    # SwiftUI views
│   ├── MainView.swift
│   ├── SettingsView.swift
│   ├── JoystickView.swift
│   └── StreamView.swift
├── Managers/                 # Services
│   ├── SSHManager.swift
│   ├── RTSPPlayer.swift
│   └── UDPClient.swift
└── Resources/               # Assets
    ├── Assets.xcassets
    └── YOLOv8n.mlmodel
```

### Swift Version

The app uses **Swift 5.7+** with SwiftUI and async/await.

### Minimum Deployment Target

iOS 15.0 - ensures AVPlayer RTSP support and modern SwiftUI features.

## 🆘 Getting Help

If you encounter issues:

1. **Check logs** in Xcode console (Cmd+Shift+Y)
2. **Review** [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
3. **Verify** all setup steps completed
4. **Check** Raspberry Pi logs
5. **Test** network connectivity

## 🔄 Updating the App

To update to a newer version:

```bash
cd yahboom-iphone-controller
git pull origin main
cd ios/YahboomController
# Clean build folder
rm -rf ~/Library/Developer/Xcode/DerivedData/YahboomController-*
# Rebuild in Xcode
```

---

**Happy robot controlling! 🤖**
