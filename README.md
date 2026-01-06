# Yahboom Rider Pi CM4 Balancing Robot Controller

A comprehensive control system for the Yahboom Rider Pi CM4 balancing robot, consisting of Raspberry Pi Python scripts for motor control and video streaming, plus an iOS application for remote control and monitoring.

## Project Overview

This project provides:
- **Raspberry Pi Scripts**: Motor control via UDP, real-time video streaming via RTSP/GStreamer
- **iOS Application**: Remote control interface with joystick controls, live video feed, and YOLOv8 object detection
- **Documentation**: Complete setup and troubleshooting guides

## Features

### Raspberry Pi Components
- UDP-based motor control system
- RTSP video streaming using GStreamer
- Configurable parameters via YAML
- Test scripts for motor and streaming validation

### iOS Application
- Real-time video streaming (RTSP)
- Custom joystick control overlay
- SSH connection management
- YOLOv8 CoreML integration for object detection
- Settings management

## Quick Start

### Prerequisites
- Yahboom Rider Pi CM4 balancing robot
- Raspberry Pi OS (Bullseye or later)
- iPhone/iPad running iOS 15.0+
- Xcode 14.0+ (for iOS development)
- Python 3.8+ on Raspberry Pi

### Setup

1. **Raspberry Pi Setup**
   ```bash
   cd pi/
   pip install -r requirements.txt
   # Edit config.yaml with your settings
   python motor_controller.py
   ```
   
   For detailed instructions, see [Raspberry Pi Setup Guide](docs/SETUP_PI.md)

2. **iOS Application Setup**
   - Open `ios/YahboomController.xcodeproj` in Xcode
   - Configure your development team
   - Build and run on your device
   
   For detailed instructions, see [iOS Setup Guide](docs/SETUP_IOS.md)

## Documentation

- [Architecture Overview](docs/ARCHITECTURE.md) - System design and component interactions
- [Raspberry Pi Setup](docs/SETUP_PI.md) - Complete Pi configuration guide
- [iOS Setup](docs/SETUP_IOS.md) - iOS app build and deployment
- [Troubleshooting](docs/TROUBLESHOOTING.md) - Common issues and solutions

## Project Structure

```
.
├── README.md
├── docs/
│   ├── ARCHITECTURE.md
│   ├── SETUP_IOS.md
│   ├── SETUP_PI.md
│   └── TROUBLESHOOTING.md
├── pi/
│   ├── config.yaml
│   ├── motor_controller.py
│   ├── requirements.txt
│   ├── rtsp_server.py
│   ├── test_motors.py
│   └── test_streaming.py
└── ios/
    └── YahboomController/
        ├── YahboomController.xcodeproj
        └── YahboomController/
            ├── ViewControllers/
            ├── Models/
            └── Resources/
```

## Testing

### Test Raspberry Pi Components
```bash
# Test motor control
python pi/test_motors.py

# Test video streaming
python pi/test_streaming.py
```

### Test iOS Application
Open the project in Xcode and run the test suite (⌘+U).

## Contributing

Contributions are welcome! Please ensure:
- Code follows existing style conventions
- All tests pass before submitting
- Documentation is updated for new features

## License

This project is provided as-is for educational and research purposes.

## Support

For issues and questions:
- Check the [Troubleshooting Guide](docs/TROUBLESHOOTING.md)
- Review the [Architecture Documentation](docs/ARCHITECTURE.md)
- Check existing GitHub issues

## Acknowledgments

- Yahboom Technology for the Rider Pi CM4 platform
- GStreamer project for video streaming capabilities
- YOLOv8 for object detection models
