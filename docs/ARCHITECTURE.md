# System Architecture

This document describes the architecture and design of the Yahboom Rider Pi CM4 balancing robot control system.

## Overview

The system consists of two main components:
1. **Raspberry Pi Backend**: Motor control and video streaming
2. **iOS Frontend**: User interface and remote control

These components communicate over a local network using UDP for motor commands and RTSP for video streaming.

## System Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                      iOS Application                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Settings   │  │  Main View   │  │ Stream View  │      │
│  │     View     │  │  (Joystick)  │  │  (Fullscreen)│      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│         │                  │                  │              │
│         └──────────────────┼──────────────────┘              │
│                            │                                 │
│  ┌─────────────────────────┼────────────────────────────┐   │
│  │         Connection Manager                           │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌──────────────┐│   │
│  │  │ SSH Manager │  │   Motor     │  │    RTSP      ││   │
│  │  │             │  │ Controller  │  │   Client     ││   │
│  │  └─────────────┘  └─────────────┘  └──────────────┘│   │
│  └──────────────────────────────────────────────────────┘   │
│                            │                                 │
│  ┌─────────────────────────┴────────────────────────────┐   │
│  │              YOLOv8 Detector (CoreML)                │   │
│  └──────────────────────────────────────────────────────┘   │
└──────────────────┬────────────────────┬─────────────────────┘
                   │                    │
                   │ UDP (Port 5005)   │ RTSP (Port 8554)
                   │ Motor Commands    │ Video Stream
                   │                    │
┌──────────────────┴────────────────────┴─────────────────────┐
│               Raspberry Pi CM4 Backend                       │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              Motor Controller (Python)               │   │
│  │  - UDP Server listening on port 5005                 │   │
│  │  - Parses joystick commands                          │   │
│  │  - Controls motors via I2C                           │   │
│  └──────────────────────┬───────────────────────────────┘   │
│                         │                                    │
│  ┌──────────────────────┴───────────────────────────────┐   │
│  │              RTSP Server (Python/GStreamer)          │   │
│  │  - Captures from Pi Camera                           │   │
│  │  - Encodes H.264 video                               │   │
│  │  - Streams via RTSP on port 8554                     │   │
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

### iOS Application

#### View Controllers

**MainViewController**
- Primary user interface
- Displays live video feed
- Joystick overlay for motor control
- Object detection visualization
- Connection status indicator

**SettingsViewController**
- Configuration management
- Network settings (IP, ports)
- Motor control parameters
- Video quality options
- SSH credentials

**StreamViewController**
- Full-screen video display
- Touch gesture controls
- Recording capabilities
- Quality adjustment

#### Models

**ConnectionManager**
- Singleton pattern for managing all connections
- Coordinates SSH, UDP, and RTSP connections
- Handles reconnection logic
- Monitors connection health

**MotorController**
- Translates joystick input to motor commands
- Formats UDP packets
- Sends commands to Raspberry Pi
- Implements command queuing and throttling

**SSHManager**
- Establishes SSH connections to Raspberry Pi
- Executes remote commands
- Manages authentication
- Used for configuration and diagnostics

**YOLODetector**
- Wraps CoreML YOLOv8 model
- Processes video frames
- Returns detected objects with bounding boxes
- Runs asynchronously on separate queue

#### Custom Views

**JoystickView**
- Touch-based joystick control
- Returns normalized X/Y values (-1.0 to 1.0)
- Visual feedback for touch position
- Supports both drag and tap modes

**VideoPlayerView**
- RTSP stream rendering using AVFoundation
- Hardware-accelerated decoding
- Handles stream buffering
- Automatic reconnection on stream loss

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

### Motor Control Flow

1. User touches joystick on iOS device
2. JoystickView calculates X/Y position
3. MotorController converts to left/right motor speeds
4. UDP packet sent to Raspberry Pi
5. motor_controller.py receives and parses packet
6. I2C commands sent to motor driver
7. Motors respond to commands

**Latency**: ~20-50ms end-to-end

### Video Streaming Flow

1. Pi Camera captures frame
2. GStreamer encodes to H.264
3. RTSP server packetizes and transmits
4. iOS device receives packets
5. AVFoundation decodes and renders
6. YOLODetector processes frame (if enabled)
7. Detected objects overlaid on display

**Latency**: ~150-300ms end-to-end

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

### iOS
- Swift 5.0+
- iOS 15.0+
- AVFoundation
- CoreML
- Network framework

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
