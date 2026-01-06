# System Architecture

This document describes the architecture and design of the Yahboom Rider Pi CM4 balancing robot control system.

## Overview

The system consists of two main components:
1. **Raspberry Pi Backend**: Motor control and video streaming
2. **iOS Frontend**: User interface and remote control (SwiftUI + MVVM)

These components communicate over a local network using UDP for motor commands and RTSP for video streaming.

## System Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                   iOS Application (SwiftUI)                  │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                   SwiftUI Views                      │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌───────────┐ │   │
│  │  │   Settings   │  │ MainControl  │  │ Joystick  │ │   │
│  │  │     View     │  │     View     │  │   View    │ │   │
│  │  └──────────────┘  └──────────────┘  └───────────┘ │   │
│  │  ┌──────────────┐  ┌──────────────┐                │   │
│  │  │VideoPlayer   │  │  Detection   │                │   │
│  │  │    View      │  │   Overlay    │                │   │
│  │  └──────────────┘  └──────────────┘                │   │
│  └──────────────────────┬─────────────────────────────┘   │
│                         │ Binding (@Published)             │
│  ┌──────────────────────┴─────────────────────────────┐   │
│  │                  ViewModels (MVVM)                  │   │
│  │  ┌─────────────────┐  ┌──────────────────────────┐│   │
│  │  │ RobotControl    │  │    Settings              ││   │
│  │  │  ViewModel      │  │    ViewModel             ││   │
│  │  │ - 20Hz Timer    │  │ - Input Validation       ││   │
│  │  │ - Emergency Stop│  │ - UserDefaults Storage   ││   │
│  │  │ - Connection    │  │ - Configuration          ││   │
│  │  └─────────────────┘  └──────────────────────────┘│   │
│  └──────────────────────┬─────────────────────────────┘   │
│                         │ Business Logic                   │
│  ┌──────────────────────┴─────────────────────────────┐   │
│  │                     Models                          │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌───────────┐ │   │
│  │  │   Motor     │  │    YOLO     │  │Connection │ │   │
│  │  │ Controller  │  │  Detector   │  │  Manager  │ │   │
│  │  │  (UDP)      │  │  (CoreML)   │  │           │ │   │
│  │  └─────────────┘  └─────────────┘  └───────────┘ │   │
│  └──────────────────────────────────────────────────────┘   │
└──────────────────┬────────────────────┬─────────────────────┘
                   │                    │
                   │ UDP (Port 5005)   │ RTSP (Port 8554)
                   │ Motor Commands    │ Video Stream
                   │ (20Hz / 50ms)     │ H.264 Encoded
                   │                    │
┌──────────────────┴────────────────────┴─────────────────────┐
│               Raspberry Pi CM4 Backend                       │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              Motor Controller (Python)               │   │
│  │  - UDP Server listening on port 5005                 │   │
│  │  - Parses JSON joystick commands                     │   │
│  │  - Controls motors via I2C                           │   │
│  │  - Emergency stop on timeout                         │   │
│  └──────────────────────┬───────────────────────────────┘   │
│                         │                                    │
│  ┌──────────────────────┴───────────────────────────────┐   │
│  │              RTSP Server (Python/GStreamer)          │   │
│  │  - Captures from Pi Camera                           │   │
│  │  - Encodes H.264 video                               │   │
│  │  - Streams via RTSP on port 8554                     │   │
│  │  - Auto-restart on client disconnect                 │   │
│  └──────────────────────┬───────────────────────────────┘   │
│                         │                                    │
│  ┌──────────────────────┴───────────────────────────────┐   │
│  │         Hardware Interface Layer                     │   │
│  │  ┌─────────────┐  ┌─────────────┐                   │   │
│  │  │   I2C Bus   │  │   Camera    │                   │   │
│  │  │ (Motors)    │  │  Interface  │                   │   │
│  │  └─────────────┘  └─────────────┘                   │   │
│  └──────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────┘
```

## Component Details

### iOS Application (SwiftUI + MVVM)

#### Architecture Pattern: MVVM

The app follows **Model-View-ViewModel** architecture for clean separation of concerns:

```
View (SwiftUI) ←→ ViewModel (@Published) ←→ Model (Business Logic)
     ↓                     ↓                        ↓
  UI Events          State Management         Network/Hardware
```

#### SwiftUI Views

**MainControlView**
- Primary user interface built with SwiftUI
- Full-screen video background
- Overlays: joystick, status, tracking toggle, emergency stop
- Reactive to ViewModel state changes via `@Published`
- Sheet presentation for settings

**JoystickSwiftUIView**
- Touch-based joystick control
- Drag gesture with constraints
- Returns normalized X/Y values (-1.0 to 1.0)
- Visual feedback with animated stick
- Spring animation on release

**VideoPlayerSwiftUIView**
- UIViewRepresentable wrapper for AVFoundation
- RTSP stream rendering
- Hardware-accelerated H.264 decoding
- Frame extraction for object detection
- Auto-reconnection on stream loss

**DetectionOverlayView**
- Displays YOLOv8 detection results
- Green bounding boxes around objects
- Labels with confidence percentages
- Coordinate conversion (Vision → SwiftUI)

**SettingsView**
- SwiftUI Form-based configuration
- Input validation before saving
- Persistent storage via UserDefaults
- Connection management
- Video resolution picker

#### ViewModels

**RobotControlViewModel** (`@MainActor class` + `ObservableObject`)
- Main state machine for robot control
- `@Published` properties for reactive UI updates
- **Joystick control at 20Hz**: Timer-based command sending (50ms intervals)
- **Emergency stop logic**: Monitors connection timeout (>1 second)
- **Connection monitoring**: 100ms check intervals
- **Video frame processing**: Passes frames to YOLODetector
- **State properties**:
  - `isConnected: Bool`
  - `connectionStatus: String`
  - `detections: [YOLODetector.Detection]`
  - `isTrackingEnabled: Bool`
  - `emergencyStopActive: Bool`

**SettingsViewModel** (`@MainActor class` + `ObservableObject`)
- Configuration management
- Input validation (IP, port, URL)
- `@Published` properties for form fields
- Video resolution selection
- Persistent storage interface
- Settings retrieval methods

#### Models

**MotorController**
- UDP-based motor control via Network framework
- Translates joystick input to motor commands
- JSON packet format: `{left: speed, right: speed, timestamp: time}`
- Differential drive calculation
- Command queuing and throttling
- Connection state management

**YOLODetector**
- Wraps CoreML YOLOv8 model
- Processes CVPixelBuffer from video stream
- Returns Detection objects with bounding boxes
- Runs on background queue
- Configurable confidence threshold
- Supports both UIImage and CVPixelBuffer inputs

**ConnectionManager**
- Legacy singleton for backward compatibility
- Coordinates MotorController instances
- Persistent settings via UserDefaults
- Connection status callbacks

**SSHManager**
- Placeholder for SSH functionality
- Credential storage (should use Keychain in production)
- Remote command execution interface

### Raspberry Pi Backend

#### motor_controller.py

**Purpose**: Receives motor control commands via UDP and controls the robot's motors.

**Key Functions**:
- `setup_motors()`: Initializes I2C interface and motor controllers
- `parse_command(data)`: Parses incoming UDP packets
- `set_motor_speeds(left, right)`: Sets motor speeds via I2C
- `run_udp_server()`: Main UDP server loop

**Protocol**: 
- UDP packets contain: `{left_speed},{right_speed},{direction}`
- Speed range: -100 to 100 (negative = reverse)
- Direction: 0 = straight, 1 = left, 2 = right

#### rtsp_server.py

**Purpose**: Captures video from Pi Camera and streams via RTSP.

**Key Functions**:
- `setup_camera()`: Configures Pi Camera parameters
- `create_gstreamer_pipeline()`: Builds GStreamer pipeline
- `start_rtsp_server()`: Initializes RTSP server
- `stream_loop()`: Main streaming loop

**GStreamer Pipeline**:
```
v4l2src → videoconvert → x264enc → rtph264pay → udpsink
```

**Configuration**:
- Resolution: 640x480 (configurable)
- Framerate: 30 fps (configurable)
- Codec: H.264
- Latency: ~200ms (typical)

#### config.yaml

**Purpose**: Central configuration file for all parameters.

**Structure**:
```yaml
network:
  motor_udp_port: 5005
  rtsp_port: 8554
  
camera:
  resolution: [640, 480]
  framerate: 30
  format: 'h264'
  
motors:
  speed_limit: 100
  acceleration: 50
  i2c_address: 0x16
  
logging:
  level: 'INFO'
  file: '/var/log/yahboom.log'
```

## Communication Protocols

### UDP Motor Control Protocol

**Packet Format**:
```
{
  "left": -100 to 100,    # Left motor speed
  "right": -100 to 100,   # Right motor speed  
  "timestamp": 1234567890 # Unix timestamp
}
```

**Characteristics**:
- Connectionless (UDP)
- Low latency (~10ms typical)
- No acknowledgment
- Fire-and-forget

### RTSP Video Streaming

**Stream URL**: `rtsp://<pi-ip>:8554/stream`

**Characteristics**:
- Connection-oriented (TCP for control, UDP for media)
- H.264 encoded video
- Standard RTSP protocol
- Compatible with VLC, ffplay, AVFoundation

### SSH Control Channel

**Purpose**: Configuration and diagnostics

**Use Cases**:
- Start/stop services remotely
- Update configuration
- Retrieve logs
- System monitoring

## Data Flow

### Motor Control Flow (SwiftUI MVVM)

1. User touches joystick on iOS device
2. **JoystickSwiftUIView** drag gesture handler calculates X/Y position
3. View calls `viewModel.updateJoystickPosition(x:y:)` method
4. **RobotControlViewModel** stores current joystick state
5. **20Hz Timer** (50ms interval) calls `sendJoystickCommand()`
6. **MotorController** converts joystick to left/right motor speeds
7. UDP packet (JSON) sent to Raspberry Pi
8. `motor_controller.py` receives and parses packet
9. I2C commands sent to motor driver
10. Motors respond to commands

**Latency**: ~20-50ms end-to-end  
**Update Rate**: Exactly 20Hz (commands sent every 50ms)  
**Emergency Stop**: Auto-trigger if no command for >1 second

**Flow Diagram**:
```
Touch Event → SwiftUI View → ViewModel → Timer (20Hz) → Model → UDP → Pi → I2C → Motors
                                ↑                                           
                                └─── @Published State Updates ────┘
```

### Video Streaming Flow

1. Pi Camera captures frame
2. GStreamer encodes to H.264
3. RTSP server packetizes and transmits
4. iOS device receives packets via AVFoundation
5. **VideoPlayerSwiftUIView** UIViewRepresentable decodes and renders
6. `CADisplayLink` extracts CVPixelBuffer (30 FPS)
7. **RobotControlViewModel** receives frame via callback
8. If tracking enabled, passes to **YOLODetector** 
9. YOLODetector processes asynchronously on background queue
10. Detection results published via `@Published var detections`
11. **DetectionOverlayView** reactively updates with bounding boxes

**Latency**: ~150-300ms end-to-end  
**Frame Rate**: 30 FPS (camera) → 30 FPS (display) → ~15-30 FPS (detection)

**Flow Diagram**:
```
Camera → GStreamer → RTSP → AVPlayer → UIView → SwiftUI → ViewModel → YOLODetector
                                                     ↓                      ↓
                                                  Display ← DetectionOverlay
```

### Settings Persistence Flow

1. User edits settings in **SettingsView**
2. SwiftUI `TextField` binds to `@Published var` in **SettingsViewModel**
3. User taps "Save" button
4. `validateSettings()` checks IP, port, URL formats
5. If valid, `saveSettings()` writes to `UserDefaults`
6. On "Connect", ViewModel calls `RobotControlViewModel.connect()`
7. Settings passed to **MotorController** initialization
8. Connection status updates published via `@Published var isConnected`
9. SwiftUI views automatically re-render

**Persistence**: UserDefaults (synchronous, automatic iCloud sync if enabled)

## Security Considerations

### Authentication
- SSH uses username/password authentication
- Consider using SSH keys for production
- No authentication on UDP motor control (local network only)

### Network Security
- All communication over local network only
- No internet exposure recommended
- Use WPA2/WPA3 for WiFi security

### Data Privacy
- Video stream is unencrypted RTSP
- Consider VPN for remote access
- No data is stored on iOS device by default

## Performance Characteristics

### Raspberry Pi Resource Usage
- CPU: ~30-40% (video encoding)
- Memory: ~200MB
- Network: ~2-5 Mbps (video stream)

### iOS App Resource Usage
- CPU: ~20-30% (video decoding + ML)
- Memory: ~100MB
- Battery: Moderate drain (streaming)

## Scalability

### Current Limitations
- Single robot support
- Local network only
- Point-to-point communication

### Future Enhancements
- Multi-robot support
- Cloud relay for remote access
- WebRTC for lower latency
- Sensor data telemetry
- Autonomous navigation modes

## Error Handling

### Connection Failures
- Automatic reconnection with exponential backoff
- User notification of connection status
- Graceful degradation (control without video, etc.)

### Stream Interruptions
- Buffer management to smooth out network jitter
- Automatic stream restart on failure
- Quality adaptation based on bandwidth

### Motor Control Failures
- Timeout-based safety stop
- Command validation before execution
- Emergency stop functionality

## Testing Strategy

### Unit Tests
- Individual component testing
- Mock network interfaces
- Motor command validation

### Integration Tests
- End-to-end communication
- Video streaming pipeline
- Error recovery scenarios

### Hardware Tests
- Motor response verification
- Camera functionality
- Network performance under load

## Dependencies

### Raspberry Pi
- Python 3.8+
- GStreamer 1.14+
- PyYAML
- python3-smbus (I2C)
- picamera2 or v4l2

### iOS (SwiftUI App)
- **Swift 5.5+** (for async/await, if used)
- **iOS 15.0+** (minimum deployment target)
- **SwiftUI** (declarative UI framework)
- **Combine** (reactive programming)
- **AVFoundation** (video playback)
- **CoreML** (machine learning)
- **Vision** (image analysis)
- **Network** (modern networking, UDP)

**No External Dependencies**: App uses only iOS system frameworks

## Configuration Management

### Development Environment
- Use mock/simulation modes
- Local video test streams
- Simulated motor responses

### Production Environment
- Optimized video encoding
- Minimal logging
- Auto-start on boot
- Monitoring and alerting

## Maintenance

### Logging
- Structured logging on both platforms
- Log rotation on Raspberry Pi
- Console logging on iOS (debug builds)

### Monitoring
- Motor controller status
- Stream health metrics
- Network connectivity
- CPU/memory usage

### Updates
- Rolling updates on Raspberry Pi
- iOS app updates via TestFlight/App Store
- Configuration hot-reload support
