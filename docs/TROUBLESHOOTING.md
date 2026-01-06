# Troubleshooting Guide

Common issues and solutions for the Yahboom Rider Pi CM4 balancing robot control system.

## Table of Contents
- [Raspberry Pi Issues](#raspberry-pi-issues)
- [iOS Application Issues](#ios-application-issues)
- [Network and Connectivity](#network-and-connectivity)
- [Video Streaming Issues](#video-streaming-issues)
- [Motor Control Issues](#motor-control-issues)
- [Performance Issues](#performance-issues)

---

## Raspberry Pi Issues

### Camera Not Detected

**Symptom**: Camera initialization fails, "Camera not found" error

**Solutions**:
1. Enable camera interface:
   ```bash
   sudo raspi-config
   # Interface Options -> Legacy Camera -> Enable
   ```

2. Check camera connection:
   ```bash
   vcgencmd get_camera
   # Should show: supported=1 detected=1
   ```

3. Test camera directly:
   ```bash
   libcamera-hello
   # Should display preview
   ```

4. Verify camera module is connected properly (reseat cable)

### I2C Communication Errors

**Symptom**: "Failed to communicate with motor controller", I2C errors

**Solutions**:
1. Enable I2C:
   ```bash
   sudo raspi-config
   # Interface Options -> I2C -> Enable
   ```

2. Check I2C devices:
   ```bash
   sudo i2cdetect -y 1
   # Should show motor controller at 0x16 (or configured address)
   ```

3. Install I2C tools:
   ```bash
   sudo apt install -y i2c-tools python3-smbus
   ```

4. Check for conflicts with other I2C devices

### UDP Server Won't Start

**Symptom**: "Address already in use" error when starting motor_controller.py

**Solutions**:
1. Check if port is in use:
   ```bash
   sudo netstat -tulpn | grep 5005
   ```

2. Kill existing process:
   ```bash
   sudo kill <PID>
   ```

3. Change port in config.yaml:
   ```yaml
   network:
     motor_udp_port: 5006  # Use different port
   ```

### RTSP Server Crashes

**Symptom**: rtsp_server.py crashes or exits unexpectedly

**Solutions**:
1. Check GStreamer installation:
   ```bash
   gst-inspect-1.0 --version
   ```

2. Test GStreamer pipeline manually:
   ```bash
   gst-launch-1.0 v4l2src device=/dev/video0 ! videoconvert ! autovideosink
   ```

3. Check camera permissions:
   ```bash
   sudo usermod -a -G video $USER
   # Logout and login again
   ```

4. Verify enough memory:
   ```bash
   free -h
   # Increase GPU memory if needed
   ```

### Python Dependencies Missing

**Symptom**: ImportError when running Python scripts

**Solutions**:
1. Reinstall dependencies:
   ```bash
   pip3 install --upgrade -r requirements.txt
   ```

2. Use virtual environment:
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   ```

3. Check Python version:
   ```bash
   python3 --version
   # Should be 3.8 or higher
   ```

---

## iOS Application Issues

### Cannot Build in Xcode

**Symptom**: Build fails with signing or dependency errors

**Solutions**:
1. Select development team in Signing & Capabilities
2. Change Bundle Identifier to unique value
3. Clean build folder: ⌘+Shift+K
4. Delete derived data:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```

5. If using CocoaPods, ensure workspace is opened:
   ```bash
   open YahboomController.xcworkspace
   ```

### App Crashes on Launch

**Symptom**: App crashes immediately after launch

**Solutions**:
1. Check console logs in Xcode (⌘+Shift+Y)
2. Verify all required permissions in Info.plist:
   - NSCameraUsageDescription
   - NSLocalNetworkUsageDescription
3. Test on different device or simulator
4. Reset app data: Delete app and reinstall
5. Check for iOS version compatibility (iOS 15.0+)

### YOLOv8 Model Not Loading

**Symptom**: Object detection doesn't work, model loading errors

**Solutions**:
1. Verify model is added to project:
   - Check file is in project navigator
   - Verify target membership includes YahboomController

2. Check model file format:
   - Must be .mlmodel or .mlmodelc
   - CoreML compatible format

3. Ensure device supports CoreML:
   - iPhone 8 or later
   - iOS 15.0 or later

4. Check model in Build Phases:
   - Should appear in "Copy Bundle Resources"

### Settings Not Persisting

**Symptom**: Settings reset after app restart

**Solutions**:
1. Check UserDefaults are properly saved:
   ```swift
   UserDefaults.standard.synchronize()
   ```

2. Verify app has not been deleted/reinstalled (clears data)
3. Check for file permission issues
4. Review Settings implementation for save logic

---

## Network and Connectivity

### Cannot Connect to Raspberry Pi

**Symptom**: "Connection failed" or timeout errors

**Solutions**:
1. Verify both devices on same network:
   ```bash
   # On Pi
   hostname -I
   
   # On Mac (to test)
   ping <pi-ip-address>
   ```

2. Check firewall settings on Pi:
   ```bash
   sudo ufw status
   # If active, ensure ports are open
   sudo ufw allow 5005/udp
   sudo ufw allow 8554/tcp
   ```

3. Verify services are running on Pi:
   ```bash
   sudo systemctl status yahboom-motor
   sudo systemctl status yahboom-rtsp
   ```

4. Test connection manually:
   ```bash
   # From Mac
   nc -u <pi-ip> 5005
   # Type test message and press Enter
   ```

5. Check iOS app has correct IP address in Settings

### Intermittent Disconnections

**Symptom**: Connection drops randomly during operation

**Solutions**:
1. Check WiFi signal strength
2. Disable WiFi power management on Pi:
   ```bash
   sudo iwconfig wlan0 power off
   ```

3. Use static IP instead of DHCP
4. Reduce network congestion (close other apps/devices)
5. Check for interference from other 2.4GHz devices
6. Consider using 5GHz WiFi if available

### High Latency

**Symptom**: Delayed response to motor commands or laggy video

**Solutions**:
1. Check network latency:
   ```bash
   ping <pi-ip-address>
   # Should be < 10ms on local network
   ```

2. Reduce video quality/resolution in config.yaml
3. Close background apps on iOS device
4. Ensure Pi is not overloaded (check with `htop`)
5. Use wired connection if possible (Ethernet adapter)

---

## Video Streaming Issues

### No Video Stream

**Symptom**: Black screen, "Stream not available" error

**Solutions**:
1. Verify RTSP server is running:
   ```bash
   ps aux | grep rtsp_server
   ```

2. Test stream with VLC on another device:
   ```bash
   vlc rtsp://<pi-ip>:8554/stream
   ```

3. Check camera is working:
   ```bash
   libcamera-hello
   ```

4. Verify correct RTSP URL in iOS app Settings
5. Check network connectivity (see Network section)

### Poor Video Quality

**Symptom**: Pixelated, blurry, or choppy video

**Solutions**:
1. Increase bitrate in config.yaml:
   ```yaml
   camera:
     bitrate: 2000000  # 2 Mbps
   ```

2. Adjust resolution:
   ```yaml
   camera:
     resolution: [1280, 720]  # Higher quality
   ```

3. Reduce framerate if network is slow:
   ```yaml
   camera:
     framerate: 20  # Lower from 30
   ```

4. Check available bandwidth
5. Ensure Pi is not throttling (check temperature):
   ```bash
   vcgencmd measure_temp
   # Should be < 80°C
   ```

### Video Freezes/Stutters

**Symptom**: Video pauses or stutters during playback

**Solutions**:
1. Increase buffer size on iOS side
2. Check network stability (see Network section)
3. Reduce CPU load on Pi:
   ```bash
   # Lower encoding quality
   # Reduce resolution
   # Close other processes
   ```

4. Update GStreamer:
   ```bash
   sudo apt update
   sudo apt upgrade gstreamer1.0*
   ```

### Audio/Video Sync Issues

**Symptom**: Audio and video out of sync (if audio enabled)

**Solutions**:
1. Disable audio if not needed (lower overhead)
2. Adjust latency settings in GStreamer pipeline
3. Use constant bitrate encoding
4. Check system clock synchronization (NTP)

---

## Motor Control Issues

### Motors Not Responding

**Symptom**: Joystick movement doesn't control motors

**Solutions**:
1. Test motors directly on Pi:
   ```bash
   python3 test_motors.py
   ```

2. Verify UDP packets are being received:
   ```bash
   # On Pi, install tcpdump
   sudo tcpdump -i any udp port 5005
   # Move joystick and check for packets
   ```

3. Check I2C communication (see I2C section above)
4. Verify power supply to motors is adequate
5. Check motor controller configuration in config.yaml

### Erratic Motor Behavior

**Symptom**: Motors move unpredictably or inconsistently

**Solutions**:
1. Check for electromagnetic interference
2. Verify motor speed limits in config.yaml:
   ```yaml
   motors:
     speed_limit: 80  # Reduce if too aggressive
   ```

3. Add smoothing/filtering to motor commands
4. Check battery voltage (low battery = erratic behavior)
5. Calibrate motors using test scripts

### One Motor Not Working

**Symptom**: Only one motor responds to commands

**Solutions**:
1. Check motor connections (swap motors to isolate issue)
2. Test individual motor with test script
3. Verify motor driver is functioning (could be hardware failure)
4. Check for short circuits or damaged wires
5. Review I2C address configuration

### Emergency Stop Not Working

**Symptom**: Cannot stop motors in emergency

**Solutions**:
1. Implement hardware emergency stop switch
2. Add timeout to motor controller:
   ```python
   # Stop motors if no command received for 1 second
   ```
3. Test emergency stop functionality regularly
4. Have physical power disconnect available

---

## Performance Issues

### Raspberry Pi High CPU Usage

**Symptom**: Pi becomes slow, high CPU usage

**Solutions**:
1. Check running processes:
   ```bash
   htop
   ```

2. Reduce video encoding quality
3. Disable desktop environment:
   ```bash
   sudo systemctl set-default multi-user.target
   ```

4. Close unnecessary services:
   ```bash
   sudo systemctl disable bluetooth
   sudo systemctl disable cups
   ```

5. Optimize Python scripts (use profiler)

### iOS App Battery Drain

**Symptom**: iPhone battery drains quickly when using app

**Solutions**:
1. Reduce video quality/framerate
2. Disable object detection when not needed
3. Lower screen brightness
4. Close background apps
5. Use Low Power Mode when appropriate

### Slow App Response

**Symptom**: UI is sluggish, delayed touch response

**Solutions**:
1. Profile app with Instruments
2. Optimize video decoding (use hardware acceleration)
3. Reduce object detection frequency
4. Move processing to background queues
5. Test on different device (could be device-specific)

### Memory Leaks

**Symptom**: App memory usage grows over time

**Solutions**:
1. Use Instruments to detect leaks
2. Check for retain cycles in Swift code
3. Properly release AVFoundation resources
4. Monitor memory with Debug Memory Graph
5. Restart app periodically as workaround

---

## General Debugging Tips

### Enable Verbose Logging

**On Raspberry Pi**:
```yaml
# config.yaml
logging:
  level: 'DEBUG'
```

**On iOS**:
```swift
// Enable debug mode
#if DEBUG
    ConnectionManager.shared.debugMode = true
#endif
```

### Check System Logs

**Raspberry Pi**:
```bash
# System logs
sudo journalctl -u yahboom-motor -f
sudo journalctl -u yahboom-rtsp -f

# Application logs
tail -f /var/log/yahboom.log
```

**iOS**:
- Open Console.app on Mac
- Connect device and filter by process name

### Network Diagnostics

**Tools**:
```bash
# Check connectivity
ping <ip-address>

# Check open ports
nmap <ip-address>

# Monitor traffic
sudo tcpdump -i wlan0

# Test UDP
nc -u <ip-address> 5005
```

### Hardware Diagnostics

**Raspberry Pi**:
```bash
# Check temperature
vcgencmd measure_temp

# Check voltage
vcgencmd measure_volts

# Check throttling
vcgencmd get_throttled

# System info
cat /proc/cpuinfo
```

---

## Getting Help

If you continue to experience issues:

1. **Check Documentation**:
   - Review [SETUP_PI.md](SETUP_PI.md)
   - Review [SETUP_IOS.md](SETUP_IOS.md)
   - Review [ARCHITECTURE.md](ARCHITECTURE.md)

2. **Gather Information**:
   - System logs (both Pi and iOS)
   - Configuration files
   - Steps to reproduce
   - Expected vs actual behavior

3. **Test Systematically**:
   - Isolate components (test each separately)
   - Use test scripts
   - Check with known-good hardware

4. **Community Support**:
   - Search existing GitHub issues
   - Post detailed bug report
   - Include logs and configuration

## Preventive Maintenance

### Regular Tasks

**Weekly**:
- Check battery health
- Verify all connections are secure
- Test emergency stop
- Check log files for errors

**Monthly**:
- Update software on Pi and iOS
- Clean camera lens
- Inspect for physical wear
- Back up configurations

**As Needed**:
- Recalibrate motors
- Update network credentials
- Review and optimize performance
- Update documentation with learnings
