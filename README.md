# Yahboom Rider Pi CM4 Balancing Robot Controller

A complete iOS application and Raspberry Pi control system for the Yahboom Rider Pi CM4 balancing robot with real-time video streaming, person tracking, and remote control capabilities.

## 🎯 Features

### iOS Application
- **Auto-connection** to the Yahboom robot using SSH
- **RTSP video streaming** with low latency (<150ms) using AVPlayer
- **Manual joystick control** overlay at the bottom of the screen
- **YOLOv8 person tracking** with CoreML integration
- **Adjustable settings** for all functionality
- **Emergency stop** when connection drops
- **Secure credential storage** using iOS Keychain

### Raspberry Pi System
- **Motor control** via UDP communication using Yahboom's SDK
- **RTSP streaming** using GStreamer for low-latency video
- **Emergency stop** with timeout handling
- **YAML configuration** for all settings
- **Test scripts** for validation

## 📁 Repository Structure

```
yahboom-iphone-controller/
├── docs/                      # Documentation
│   ├── SETUP_IOS.md          # iOS setup guide
│   ├── SETUP_PI.md           # Raspberry Pi setup guide
│   ├── ARCHITECTURE.md       # System architecture
│   └── TROUBLESHOOTING.md    # Common issues and solutions
├── ios/                       # iOS application
│   ├── YahboomController/    # Main Xcode project
│   │   ├── Models/           # Data models
│   │   ├── ViewModels/       # Business logic
│   │   ├── Views/            # SwiftUI views
│   │   ├── Managers/         # Network and connection managers
│   │   └── Resources/        # Assets and CoreML models
│   └── .gitignore
├── pi/                        # Raspberry Pi scripts
│   ├── motor_controller.py   # Motor control via UDP
│   ├── rtsp_server.py        # RTSP streaming server
│   ├── test_motors.py        # Motor testing script
│   ├── test_streaming.py     # Streaming test script
│   ├── config.yaml           # Configuration file
│   ├── requirements.txt      # Python dependencies
│   └── .gitignore
└── README.md                  # This file
```

## 🚀 Quick Start

### Prerequisites

**For iOS Development:**
- macOS 12.0 or later
- Xcode 14.0 or later
- iPhone running iOS 15.0 or later (tested on iPhone 12)
- Apple Developer account (for device deployment)

**For Raspberry Pi:**
- Yahboom Rider Pi CM4 balancing robot
- Raspberry Pi OS (Bullseye or later)
- Python 3.8 or later
- Camera module connected
- Network connectivity (WiFi recommended)

### Raspberry Pi Setup

1. **Clone the repository** on your Raspberry Pi:
   ```bash
   git clone https://github.com/tchdvz6sp2-png/yahboom-iphone-controller.git
   cd yahboom-iphone-controller/pi
   ```

2. **Install dependencies**:
   ```bash
   pip3 install -r requirements.txt
   ```

3. **Configure settings** in `config.yaml`:
   ```bash
   nano config.yaml
   # Edit robot IP, ports, and motor settings
   ```

4. **Test motor control**:
   ```bash
   python3 test_motors.py
   ```

5. **Start the RTSP server**:
   ```bash
   python3 rtsp_server.py
   ```

6. **Start the motor controller**:
   ```bash
   python3 motor_controller.py
   ```

For detailed setup instructions, see [docs/SETUP_PI.md](docs/SETUP_PI.md).

### iOS Setup

1. **Open the Xcode project**:
   ```bash
   cd ios/YahboomController
   open YahboomController.xcodeproj
   ```

2. **Configure your development team** in Xcode:
   - Select the project in the navigator
   - Under "Signing & Capabilities", select your team

3. **Update the robot connection settings**:
   - Edit the default settings in `Models/RobotSettings.swift`
   - Or configure them in the app's Settings page

4. **Build and run** on your iPhone:
   - Select your iPhone as the target device
   - Click the Run button (Cmd+R)

For detailed setup instructions, see [docs/SETUP_IOS.md](docs/SETUP_IOS.md).

## 🎮 Usage

1. **Power on** the Yahboom robot and ensure it's connected to WiFi
2. **Start the Raspberry Pi scripts** (RTSP server and motor controller)
3. **Launch the iOS app** on your iPhone
4. **Configure connection** in Settings:
   - Enter robot IP address
   - Set SSH username and password
   - Configure RTSP stream URL
5. **Connect** to the robot using the Connect button
6. **View the live stream** and use the joystick for manual control
7. **Enable person tracking** in Settings to use YOLOv8 tracking

## 🛠️ Development

### Building the iOS App

```bash
cd ios/YahboomController
xcodebuild -scheme YahboomController -configuration Debug
```

### Running Tests on Raspberry Pi

```bash
# Test motor control
python3 pi/test_motors.py

# Test video streaming
python3 pi/test_streaming.py
```

## 📚 Documentation

- [iOS Setup Guide](docs/SETUP_IOS.md) - Complete iOS build and deployment instructions
- [Raspberry Pi Setup Guide](docs/SETUP_PI.md) - Raspberry Pi configuration and setup
- [Architecture](docs/ARCHITECTURE.md) - System architecture and design decisions
- [Troubleshooting](docs/TROUBLESHOOTING.md) - Common issues and solutions

## 🔐 Security

- SSH credentials are stored securely in iOS Keychain
- No hardcoded passwords in the codebase
- Network communication uses encrypted SSH tunnels
- Motor control timeout prevents runaway commands

## 🤝 Contributing

This is a personal project for controlling the Yahboom Rider Pi CM4 robot. Feel free to fork and adapt for your own use.

## 📝 License

This project is provided as-is for educational and personal use.

## 🙏 Acknowledgments

- Yahboom for the Rider Pi CM4 robot platform
- GStreamer project for video streaming
- YOLOv8 and Ultralytics for object detection
- Apple for CoreML and SwiftUI frameworks

## 📞 Support

For issues and questions:
- Check [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
- Review the documentation in the `docs/` folder
- Ensure all setup steps were completed correctly

## 🔄 System Requirements

### iOS App
- iPhone 12 or later (optimized for iPhone 12)
- iOS 15.0 or later
- WiFi connectivity
- ~100MB free storage

### Raspberry Pi
- Yahboom Rider Pi CM4 with CM4 module
- 2GB RAM minimum
- Camera module (CSI or USB)
- WiFi or Ethernet connectivity
- 8GB+ SD card

## ⚡ Performance

- Video latency: <150ms (optimized)
- Control response: <50ms
- Person tracking: ~15-30 FPS on iPhone 12
- Motor control update rate: 20Hz

---

**Made with ❤️ for robotics enthusiasts**
