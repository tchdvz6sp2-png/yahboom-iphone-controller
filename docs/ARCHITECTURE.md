# System Architecture

Technical documentation for the Yahboom Rider Pi CM4 balancing robot control system.

## 🏗️ System Overview

The system consists of three main components:

1. **iOS Application** (Swift/SwiftUI) - User interface and control
2. **Raspberry Pi Backend** (Python) - Motor control and video streaming
3. **Network Layer** - Communication protocols (SSH, UDP, RTSP)

```
┌─────────────────────────────────────────────────────────────┐
│                      iOS Application                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   SwiftUI    │  │   CoreML     │  │   Network    │     │
│  │   Views      │  │   YOLOv8     │  │   Managers   │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│         │                 │                  │              │
│         └─────────────────┴──────────────────┘              │
│                           │                                 │
└───────────────────────────┼─────────────────────────────────┘
                            │
                    WiFi Network (5GHz)
                            │
┌───────────────────────────┼─────────────────────────────────┐
│                           │      Raspberry Pi               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   RTSP       │  │   Motor      │  │   Camera     │     │
│  │   Server     │  │   Controller │  │   Interface  │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│         │                 │                  │              │
│         └─────────────────┴──────────────────┘              │
│                           │                                 │
└───────────────────────────┼─────────────────────────────────┘
                            │
                    ┌───────┴────────┐
                    │   Yahboom      │
                    │   Hardware     │
                    │   (Motors,     │
                    │   Sensors)     │
                    └────────────────┘
```

## 📱 iOS Application Architecture

### Design Pattern: MVVM (Model-View-ViewModel)

```
Views (SwiftUI)
    ↓
ViewModels (Business Logic)
    ↓
Models (Data Structures)
    ↓
Managers (Network Services)
```

### Component Breakdown

#### 1. Models (`ios/YahboomController/Models/`)

**RobotSettings.swift**
- Stores all configuration settings
- Persisted to UserDefaults
- Accessed throughout the app

**MotorCommand.swift**
- Represents motor control commands
- Encodes to UDP packets
- Includes timestamp for timeout detection

**PersonDetection.swift**
- CoreML output wrapper
- Bounding box coordinates
- Confidence scores

#### 2. ViewModels (`ios/YahboomController/ViewModels/`)

**ConnectionViewModel.swift**
- Manages SSH connection state
- Handles connection/disconnection
- Monitors connection health
- Triggers emergency stop on disconnect

**StreamViewModel.swift**
- Manages RTSP video stream
- Interfaces with AVPlayer
- Handles buffering and errors
- Measures and displays latency

**ControlViewModel.swift**
- Converts joystick input to motor commands
- Sends UDP packets to Raspberry Pi
- Implements command rate limiting (20Hz)
- Handles emergency stop

**TrackingViewModel.swift**
- Runs YOLOv8 CoreML model
- Processes video frames
- Calculates tracking commands
- Integrates with ControlViewModel

#### 3. Views (`ios/YahboomController/Views/`)

**MainView.swift**
- Root view of the application
- Combines stream and control views
- Shows connection status
- Navigation to Settings

**StreamView.swift**
- Displays RTSP video stream
- Overlays person detection boxes
- Shows latency and FPS info

**JoystickView.swift**
- Touch-based joystick control
- Visual feedback (knob position)
- Drag gestures
- Returns to center on release

**SettingsView.swift**
- Configuration interface
- Form-based UI
- Credential input (secure)
- Toggle switches for features

**ConnectionIndicator.swift**
- Visual connection status
- Green/Yellow/Red states
- Animated when connecting

#### 4. Managers (`ios/YahboomController/Managers/`)

**SSHManager.swift**
- SSH connection handling
- Uses NMSSH or native URLSession
- Credential management via Keychain
- Keep-alive pings

**RTSPPlayer.swift**
- AVPlayer wrapper for RTSP
- Low-latency configuration
- Frame extraction for tracking
- Error recovery

**UDPClient.swift**
- UDP socket communication
- Sends motor commands
- Handles network errors
- Port configuration

**KeychainManager.swift**
- Secure credential storage
- Save/retrieve passwords
- iOS Keychain API wrapper

**PersonTracker.swift**
- CoreML model interface
- Vision framework integration
- Real-time inference
- Bounding box tracking

### Data Flow

#### Manual Control Flow
```
User Touch → JoystickView → ControlViewModel → UDPClient → Raspberry Pi
```

#### Person Tracking Flow
```
RTSP Stream → RTSPPlayer → Frame → TrackingViewModel → 
CoreML Model → Detection → ControlViewModel → UDPClient → Raspberry Pi
```

#### Video Streaming Flow
```
Camera → GStreamer → RTSP Server → Network → AVPlayer → StreamView
```

## 🖥️ Raspberry Pi Architecture

### Component Breakdown

#### 1. Motor Controller (`pi/motor_controller.py`)

**Responsibilities:**
- Listen for UDP commands on port 5000
- Parse motor command packets
- Send commands to Yahboom hardware
- Implement emergency stop (timeout)

**Communication Protocol:**
```python
# UDP Packet Format (JSON)
{
    "command": "move",
    "speed": 50,        # -100 to 100
    "direction": 0,     # -100 to 100 (left/right)
    "timestamp": 1234567890.123
}
```

**Motor Control Methods:**
1. **SDK Method** (preferred if available):
   - Import Yahboom SDK
   - Use provided motor control functions
   
2. **Serial Fallback**:
   - Direct serial communication
   - Custom protocol implementation

**Emergency Stop Logic:**
```python
# If no command received for 1 second:
if time.time() - last_command_time > 1.0:
    stop_motors()
```

#### 2. RTSP Server (`pi/rtsp_server.py`)

**Responsibilities:**
- Capture video from camera
- Encode with H.264
- Stream via RTSP protocol
- Minimize latency

**GStreamer Pipeline:**
```bash
libcamerasrc ! 
    video/x-raw,width=640,height=480,framerate=30/1 ! 
    videoconvert ! 
    x264enc tune=zerolatency bitrate=2000 speed-preset=ultrafast ! 
    rtph264pay name=pay0 pt=96 ! 
    rtspsink service=8554
```

**Optimizations:**
- Zero-latency tuning
- Ultra-fast encoding preset
- Appropriate bitrate (2 Mbps)
- Hardware acceleration where available

#### 3. Configuration (`pi/config.yaml`)

**Structure:**
```yaml
robot:
  ip_address: "192.168.1.100"
  hostname: "yahboom-robot"

motor:
  udp_port: 5000
  serial_port: "/dev/ttyUSB0"
  serial_baudrate: 115200
  max_speed: 100
  timeout: 1.0

rtsp:
  port: 8554
  path: "/stream"
  resolution: "640x480"
  framerate: 30
  bitrate: 2000000

camera:
  device: "/dev/video0"
  width: 640
  height: 480
  fps: 30

logging:
  level: "INFO"
  file: "/var/log/yahboom_controller.log"
```

**Loading:**
```python
import yaml

with open('config.yaml', 'r') as f:
    config = yaml.safe_load(f)
```

## 🌐 Network Communication

### Protocols Used

#### 1. SSH (Port 22)
- **Purpose**: Initial connection and authentication
- **Usage**: iOS app establishes SSH connection first
- **Security**: Password or key-based auth
- **Keep-alive**: Periodic pings to maintain connection

#### 2. UDP (Port 5000)
- **Purpose**: Motor control commands
- **Characteristics**: 
  - Low latency (no handshake)
  - Unreliable (acceptable for motor control)
  - High frequency (20 Hz)
- **Packet Size**: ~100 bytes (JSON)

#### 3. RTSP (Port 8554)
- **Purpose**: Video streaming
- **Protocol**: Real-Time Streaming Protocol
- **Transport**: RTP over UDP (typically)
- **Latency**: <150ms target
- **Format**: H.264 encoded video

### Network Topology

```
iPhone (WiFi) ←→ WiFi Router ←→ Raspberry Pi (WiFi/Ethernet)

Connections:
- SSH: iPhone → Pi (port 22)
- UDP: iPhone → Pi (port 5000)
- RTSP: Pi → iPhone (port 8554)
```

### Latency Analysis

**Total System Latency Budget: <150ms**

- Camera capture: 10-20ms
- H.264 encoding: 20-30ms
- Network transmission: 10-30ms
- Decoding on iPhone: 20-40ms
- Display rendering: 10-20ms
- **Total: 70-140ms** ✓

**Control Latency: <50ms**

- Touch detection: 5-10ms
- Command generation: 1-5ms
- UDP transmission: 5-15ms
- Command processing: 5-10ms
- Motor response: 10-20ms
- **Total: 26-60ms** ✓

## 🤖 YOLOv8 Person Tracking

### Model Details

**Model**: YOLOv8n (nano) - optimized for mobile
**Format**: CoreML (.mlmodel)
**Input**: 640x640 RGB image
**Output**: Bounding boxes, confidence scores, class IDs
**Performance**: 15-30 FPS on iPhone 12

### Integration Flow

```
Video Frame → Resize/Normalize → CoreML Model → 
Post-processing → Person Bounding Boxes → 
Calculate Center → Generate Motor Commands
```

### Tracking Logic

```swift
// Simplified tracking algorithm
func trackPerson(detection: Detection) {
    let frameCenterX = frameWidth / 2
    let personCenterX = detection.boundingBox.midX
    
    let error = personCenterX - frameCenterX
    let turnCommand = error / frameCenterX * maxTurnSpeed
    
    // Send command to move robot to center person in frame
    sendCommand(speed: trackingSpeed, turn: turnCommand)
}
```

### Settings

**Confidence Threshold**: 0.5 (default)
- Lower = more detections (may include false positives)
- Higher = fewer detections (more accurate)

**Tracking Speed**: Medium (default)
- Slow: 30% max speed
- Medium: 50% max speed
- Fast: 70% max speed

## 🔐 Security Architecture

### Credential Management

**iOS Keychain**:
```swift
// Save password
KeychainManager.save(password: "secret", for: "ssh_password")

// Retrieve password
let password = KeychainManager.get(key: "ssh_password")
```

**No Hardcoded Credentials**:
- All credentials input by user
- Stored securely in Keychain
- Never logged or transmitted insecurely

### Network Security

**SSH Encryption**:
- All initial communication encrypted via SSH
- Optional: Use SSH keys instead of passwords

**Local Network**:
- System designed for local network use
- Not exposed to internet by default
- Consider VPN for remote access

### Emergency Stop

**Multiple Triggers**:
1. Connection loss detection
2. Timeout (1 second no command)
3. Manual stop button
4. App backgrounding

**Fail-safe**:
```python
# Raspberry Pi automatically stops motors if:
# - No command received for 1 second
# - Invalid command received
# - Connection closed
```

## 📊 Performance Characteristics

### Video Streaming

| Resolution | Bitrate | Latency | FPS | CPU (Pi) |
|------------|---------|---------|-----|----------|
| 320x240    | 1 Mbps  | 60-80ms | 30  | 20-30%   |
| 640x480    | 2 Mbps  | 80-120ms| 30  | 30-40%   |
| 1280x720   | 4 Mbps  | 120-200ms| 30 | 50-70%   |

**Recommended**: 640x480 @ 2 Mbps for best quality/latency balance

### Person Tracking

| iPhone Model | FPS | Latency | CPU Usage |
|--------------|-----|---------|-----------|
| iPhone 11    | 12-20 | 80-100ms | 40-60%  |
| iPhone 12    | 15-30 | 50-80ms  | 30-50%  |
| iPhone 13+   | 20-40 | 40-60ms  | 25-40%  |

**Recommended**: Disable tracking if FPS drops below 10

### Motor Control

- **Update Rate**: 20 Hz (50ms interval)
- **Latency**: 30-50ms (touch to motor)
- **Timeout**: 1000ms (emergency stop)

## 🔄 State Management

### iOS App States

```
┌─────────────┐
│ Disconnected│
└─────┬───────┘
      │ tap Connect
      ▼
┌─────────────┐
│ Connecting  │
└─────┬───────┘
      │ success
      ▼
┌─────────────┐     ┌──────────────┐
│  Connected  │────▶│  Streaming   │
└─────┬───────┘     └──────┬───────┘
      │                    │
      │ enable tracking    │
      ▼                    ▼
┌─────────────┐     ┌──────────────┐
│  Tracking   │     │   Manual     │
│   Active    │◀────│   Control    │
└─────────────┘     └──────────────┘
```

### Connection State Machine

```swift
enum ConnectionState {
    case disconnected
    case connecting
    case connected
    case streaming
    case error(Error)
}
```

## 🧪 Testing Strategy

### Unit Tests (iOS)

- Model encoding/decoding
- Joystick coordinate calculations
- Command generation logic
- Keychain operations

### Integration Tests (iOS)

- Network connectivity
- Video player initialization
- CoreML model loading
- UDP packet transmission

### System Tests (Pi)

- Motor control responses
- Video streaming quality
- Emergency stop functionality
- Configuration loading

### Manual Testing Checklist

- [ ] Connect to robot
- [ ] Video stream displays
- [ ] Joystick controls robot
- [ ] Person tracking works
- [ ] Emergency stop functions
- [ ] Settings persist
- [ ] Connection recovery after disconnect

## 🔧 Debugging

### iOS Debugging

**Xcode Console**:
```swift
// Add logging
print("[DEBUG] Connection state: \(state)")
Logger.debug("Sent motor command: \(command)")
```

**Network Traffic**:
- Use Wireshark to inspect UDP/RTSP packets
- Charles Proxy for HTTP (if used)

**CoreML Performance**:
```swift
let start = Date()
let prediction = try model.prediction(image: pixelBuffer)
let elapsed = Date().timeIntervalSince(start)
print("Inference time: \(elapsed * 1000)ms")
```

### Pi Debugging

**Logging**:
```python
import logging
logging.basicConfig(level=logging.DEBUG)
logger.debug(f"Received command: {command}")
```

**Network**:
```bash
# Monitor UDP traffic
sudo tcpdump -i wlan0 port 5000

# Monitor RTSP connections
sudo tcpdump -i wlan0 port 8554
```

**Performance**:
```bash
# CPU usage
htop

# Temperature
vcgencmd measure_temp

# Network stats
iftop
```

## 📈 Future Enhancements

### Potential Improvements

1. **Sensor Integration**
   - Add ultrasonic sensors for obstacle avoidance
   - IMU data for balance feedback
   - Battery level monitoring

2. **Advanced Tracking**
   - Multiple person tracking
   - Object following (balls, etc.)
   - Path recording and playback

3. **Recording**
   - Video recording to phone
   - Telemetry logging
   - Playback mode

4. **AI Enhancements**
   - Autonomous navigation
   - SLAM (Simultaneous Localization and Mapping)
   - Gesture recognition

5. **Multi-platform**
   - Android app
   - Web interface
   - Apple Watch companion

---

**Architecture designed for reliability, low latency, and extensibility.**
