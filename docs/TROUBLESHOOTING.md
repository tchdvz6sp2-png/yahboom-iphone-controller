# Troubleshooting Guide

Common issues and solutions for the Yahboom Rider Pi CM4 balancing robot control system.

## 📱 iOS App Issues

### App Won't Install on iPhone

**Symptom**: Error when trying to install app on device

**Possible Causes & Solutions**:

1. **"Untrusted Developer" message**
   ```
   Solution:
   1. Go to iPhone Settings
   2. General → VPN & Device Management
   3. Tap on your developer account
   4. Tap "Trust [Your Account]"
   5. Confirm by tapping "Trust"
   ```

2. **Provisioning profile error**
   ```
   Solution:
   1. In Xcode, select the project
   2. Go to Signing & Capabilities
   3. Ensure your Team is selected
   4. Try changing the Bundle Identifier
   5. Clean build folder (Cmd+Shift+K)
   6. Rebuild and try again
   ```

3. **Device not recognized**
   ```
   Solution:
   1. Disconnect and reconnect iPhone
   2. Unlock the iPhone
   3. Trust the computer when prompted
   4. Restart Xcode if needed
   ```

### Video Stream Not Showing

**Symptom**: Black screen or "No Stream" message in the app

**Diagnostic Steps**:
```
1. Check connection indicator - is it green?
2. Check Settings - is RTSP URL correct?
3. Check Raspberry Pi - is rtsp_server.py running?
4. Test stream on computer first (VLC/ffplay)
```

**Solutions**:

1. **RTSP server not running on Pi**
   ```bash
   # On Raspberry Pi
   cd ~/yahboom-iphone-controller/pi
   python3 rtsp_server.py
   
   # Should see: "Server ready on rtsp://..."
   ```

2. **Wrong RTSP URL in app**
   ```
   Correct format: rtsp://[PI_IP]:8554/stream
   Example: rtsp://192.168.1.100:8554/stream
   
   Common mistakes:
   - Using http:// instead of rtsp://
   - Wrong IP address
   - Missing /stream path
   - Wrong port number
   ```

3. **Network connectivity issue**
   ```bash
   # On iPhone: Settings → WiFi
   # Verify connected to same network as Pi
   
   # Test connectivity
   # On computer on same network:
   ping [PI_IP]
   ```

4. **Camera not working on Pi**
   ```bash
   # Test camera
   libcamera-hello --timeout 5000
   
   # Check camera is enabled
   vcgencmd get_camera
   # Should show: supported=1 detected=1
   
   # If not, enable in raspi-config
   sudo raspi-config
   # Interface Options → Camera → Enable
   ```

5. **Firewall blocking port**
   ```bash
   # On Raspberry Pi
   sudo ufw allow 8554/tcp
   sudo ufw reload
   ```

### Joystick Not Responding

**Symptom**: Touch input on joystick doesn't control robot

**Diagnostic Steps**:
```
1. Is connection indicator green?
2. Are you seeing motor controller logs on Pi?
3. Try the test_motors.py script on Pi
```

**Solutions**:

1. **Not connected to robot**
   ```
   - Ensure connection indicator is green
   - Try disconnecting and reconnecting
   - Check Settings for correct IP/credentials
   ```

2. **Motor controller not running**
   ```bash
   # On Raspberry Pi
   cd ~/yahboom-iphone-controller/pi
   python3 motor_controller.py
   
   # Should see: "Motor controller listening on port 5000"
   ```

3. **UDP port mismatch**
   ```
   Check both:
   - iOS Settings → UDP Port (default: 5000)
   - Pi config.yaml → motor.udp_port (should match)
   ```

4. **Firewall blocking UDP**
   ```bash
   # On Raspberry Pi
   sudo ufw allow 5000/udp
   sudo ufw reload
   ```

5. **Motor hardware issue**
   ```bash
   # Test motors directly
   python3 test_motors.py
   
   # Check serial connection
   ls -l /dev/ttyUSB* /dev/ttyAMA*
   
   # Verify permissions
   groups
   # Should include 'dialout'
   ```

### Person Tracking Not Working

**Symptom**: No detection boxes appearing, or tracking not following people

**Solutions**:

1. **Tracking not enabled**
   ```
   - Go to Settings
   - Toggle "Enable Tracking" to ON
   - Return to main screen
   ```

2. **Confidence threshold too high**
   ```
   - Go to Settings
   - Lower "Confidence Threshold" to 0.3 or 0.4
   - Higher values = fewer detections
   - Lower values = more detections (but may include false positives)
   ```

3. **Poor lighting conditions**
   ```
   - Ensure good lighting
   - Avoid backlit scenarios
   - Try in different environment
   ```

4. **CoreML model not loaded**
   ```
   Check Xcode console for errors like:
   "Failed to load CoreML model"
   
   Solution:
   - Ensure YOLOv8n.mlmodel is in project
   - Check Build Phases → Copy Bundle Resources
   - Model should be included
   ```

5. **Performance issues**
   ```
   If FPS is very low (<5):
   - Close other apps on iPhone
   - Reduce video resolution in Pi config
   - Try disabling and re-enabling tracking
   - Restart the app
   ```

6. **Person not in frame**
   ```
   - Ensure person is visible in video stream
   - Try moving person closer/further
   - Ensure person is fully visible (not cut off)
   ```

### App Crashes or Freezes

**Symptom**: App crashes or becomes unresponsive

**Solutions**:

1. **Check Xcode console for crash logs**
   ```
   Look for:
   - Fatal errors
   - Exception traces
   - Memory warnings
   ```

2. **Memory pressure**
   ```
   - Close other apps on iPhone
   - Restart iPhone
   - Check for memory leaks in Xcode Instruments
   ```

3. **Network timeout**
   ```
   - Check network connectivity
   - Verify Pi is reachable
   - Try increasing timeout in Settings
   ```

4. **CoreML model issue**
   ```
   - Disable person tracking
   - If app stops crashing, issue is with CoreML
   - Check model is compatible with iOS version
   ```

### Connection Keeps Dropping

**Symptom**: Frequent "Disconnected" messages

**Solutions**:

1. **Weak WiFi signal**
   ```
   - Check WiFi signal strength on iPhone
   - Move closer to WiFi router
   - Switch to 5GHz WiFi if available
   ```

2. **SSH connection timeout**
   ```
   On Raspberry Pi, edit SSH config:
   sudo nano /etc/ssh/sshd_config
   
   Add/modify:
   ClientAliveInterval 30
   ClientAliveCountMax 3
   
   Restart SSH:
   sudo systemctl restart ssh
   ```

3. **Network congestion**
   ```
   - Reduce network traffic (pause downloads, etc.)
   - Use dedicated WiFi network for robot
   - Configure QoS on router to prioritize robot traffic
   ```

4. **Keep-alive not working**
   ```
   - Check app Settings for keep-alive interval
   - Lower interval if available (e.g., 10 seconds)
   ```

### High Video Latency

**Symptom**: Significant delay between action and video response (>200ms)

**Solutions**:

1. **Use 5GHz WiFi**
   ```
   - 5GHz has lower latency than 2.4GHz
   - Configure on both iPhone and Pi
   - Check router supports 5GHz
   ```

2. **Reduce video resolution**
   ```bash
   # On Raspberry Pi, edit config.yaml
   nano ~/yahboom-iphone-controller/pi/config.yaml
   
   Change:
   rtsp:
     resolution: "320x240"  # Lower than 640x480
     framerate: 24          # Lower than 30
     bitrate: 1000000       # 1 Mbps instead of 2
   
   Restart RTSP server
   ```

3. **Network issues**
   ```
   - Check for packet loss: ping [PI_IP]
   - Test bandwidth: iperf3
   - Reduce interference (microwave, etc.)
   ```

4. **GStreamer pipeline optimization**
   ```python
   # In rtsp_server.py, ensure using:
   # - tune=zerolatency
   # - speed-preset=ultrafast
   # - Appropriate bitrate
   ```

5. **Pi CPU overload**
   ```bash
   # Check CPU usage
   htop
   
   # Check temperature
   vcgencmd measure_temp
   
   # If high (>70°C):
   - Add heatsink/fan
   - Reduce video resolution
   - Close other processes
   ```

## 🖥️ Raspberry Pi Issues

### Camera Not Detected

**Symptom**: Camera not working or not detected

**Solutions**:

1. **Check camera connection**
   ```bash
   # Verify camera is detected
   vcgencmd get_camera
   # Should show: supported=1 detected=1
   
   # List cameras
   libcamera-hello --list-cameras
   ```

2. **Enable camera in config**
   ```bash
   sudo raspi-config
   # Interface Options → Camera → Enable
   
   # Or manually edit config.txt
   sudo nano /boot/config.txt
   
   # Add or uncomment:
   camera_auto_detect=1
   dtoverlay=imx219  # For Pi Camera v2
   
   # Reboot
   sudo reboot
   ```

3. **Check camera cable**
   ```
   - Power off Pi
   - Disconnect camera cable
   - Check for damage
   - Reconnect firmly (blue side toward Ethernet port)
   - Power on and test
   ```

4. **Test with different software**
   ```bash
   # Test with libcamera
   libcamera-still -o test.jpg
   
   # Test with raspistill (older)
   raspistill -o test.jpg
   
   # Test with GStreamer
   gst-launch-1.0 libcamerasrc ! videoconvert ! autovideosink
   ```

### RTSP Server Won't Start

**Symptom**: rtsp_server.py fails to start or crashes

**Solutions**:

1. **Check GStreamer installation**
   ```bash
   # Verify GStreamer is installed
   gst-launch-1.0 --version
   
   # Install if missing
   sudo apt install -y \
     gstreamer1.0-tools \
     gstreamer1.0-plugins-base \
     gstreamer1.0-plugins-good \
     gstreamer1.0-plugins-bad \
     python3-gst-1.0
   ```

2. **Port already in use**
   ```bash
   # Check if port 8554 is in use
   sudo netstat -tulpn | grep 8554
   
   # Kill process using port
   sudo kill [PID]
   
   # Or change port in config.yaml
   ```

3. **Camera in use by another process**
   ```bash
   # Check for processes using camera
   sudo lsof | grep video0
   
   # Stop other camera processes
   sudo killall libcamera-hello
   sudo killall rpicam-hello
   ```

4. **Check Python dependencies**
   ```bash
   cd ~/yahboom-iphone-controller/pi
   pip3 install -r requirements.txt
   ```

5. **Check logs**
   ```bash
   # Run with verbose output
   python3 rtsp_server.py --verbose
   
   # Check system logs
   sudo journalctl -u yahboom-rtsp.service -n 50
   ```

### Motor Controller Not Working

**Symptom**: motor_controller.py not responding to commands

**Solutions**:

1. **Serial port issues**
   ```bash
   # List serial ports
   ls -l /dev/ttyUSB* /dev/ttyAMA* /dev/serial*
   
   # Check permissions
   groups
   # Should include 'dialout'
   
   # Add user to dialout group if missing
   sudo usermod -a -G dialout $USER
   # Reboot required
   sudo reboot
   ```

2. **Wrong serial port in config**
   ```bash
   nano ~/yahboom-iphone-controller/pi/config.yaml
   
   # Try different ports:
   # /dev/ttyUSB0  (USB serial adapter)
   # /dev/ttyAMA0  (GPIO serial)
   # /dev/serial0  (symbolic link)
   ```

3. **Baudrate mismatch**
   ```yaml
   # In config.yaml, try different baudrates:
   motor:
     serial_baudrate: 115200  # or 9600, 57600, etc.
   ```

4. **Hardware connection**
   ```
   - Check motor driver board is powered
   - Verify serial TX/RX connections
   - Check ground connection
   - Test with Yahboom's official software
   ```

5. **UDP not working**
   ```bash
   # Test UDP reception
   nc -ul 5000
   
   # In another terminal, send test packet
   echo "test" | nc -u localhost 5000
   
   # Should see "test" in first terminal
   ```

### High CPU Usage

**Symptom**: Raspberry Pi running slow, high temperature

**Solutions**:

1. **Reduce video resolution**
   ```yaml
   # In config.yaml
   rtsp:
     resolution: "320x240"  # Lower resolution
     framerate: 24          # Lower framerate
   ```

2. **Close unnecessary services**
   ```bash
   # Disable Bluetooth if not needed
   sudo systemctl disable bluetooth
   
   # Disable WiFi if using Ethernet
   sudo systemctl disable wpa_supplicant
   
   # Check running processes
   htop
   # Press F9 to kill unnecessary processes
   ```

3. **Add cooling**
   ```
   - Install heatsink on CPU
   - Add fan (5V fan on GPIO pins)
   - Ensure adequate ventilation
   ```

4. **Check for runaway processes**
   ```bash
   top
   # Look for processes using >50% CPU
   # Kill if unexpected
   ```

5. **Optimize GStreamer**
   ```python
   # In rtsp_server.py, ensure using hardware encoding:
   # - Use h264omx or v4l2h264enc (hardware encoders)
   # - Not x264enc (software encoder)
   ```

### Network Connectivity Issues

**Symptom**: Can't ping or connect to Raspberry Pi

**Solutions**:

1. **Find IP address**
   ```bash
   # On Pi (direct access)
   hostname -I
   
   # From router
   # Check DHCP leases in router admin
   
   # Using nmap (from computer)
   nmap -sn 192.168.1.0/24 | grep yahboom
   ```

2. **Set static IP**
   ```bash
   sudo nano /etc/dhcpcd.conf
   
   # Add at end:
   interface wlan0
   static ip_address=192.168.1.100/24
   static routers=192.168.1.1
   static domain_name_servers=8.8.8.8
   
   sudo reboot
   ```

3. **WiFi connection issues**
   ```bash
   # Check WiFi status
   iwconfig
   
   # Reconfigure WiFi
   sudo raspi-config
   # System Options → Wireless LAN
   
   # Or edit wpa_supplicant
   sudo nano /etc/wpa_supplicant/wpa_supplicant.conf
   ```

4. **Firewall blocking**
   ```bash
   # Check firewall status
   sudo ufw status
   
   # Allow necessary ports
   sudo ufw allow 22/tcp    # SSH
   sudo ufw allow 5000/udp  # Motor control
   sudo ufw allow 8554/tcp  # RTSP
   
   # Reload
   sudo ufw reload
   ```

### SD Card Issues

**Symptom**: Slow performance, corruption errors

**Solutions**:

1. **Check SD card health**
   ```bash
   # Check for errors
   sudo dmesg | grep mmc
   
   # File system check (requires reboot to read-only)
   sudo fsck -f /dev/mmcblk0p2
   ```

2. **Backup and reformat**
   ```bash
   # Backup important files
   rsync -av ~/yahboom-iphone-controller /backup/location
   
   # Reformat and reinstall OS
   # Use Raspberry Pi Imager
   ```

3. **Use quality SD card**
   ```
   - Use Class 10 or UHS-I card
   - SanDisk or Samsung recommended
   - Minimum 16GB
   ```

## 🔧 General Troubleshooting

### Get System Information

**iOS App**:
```
Settings → About
- App version
- iOS version
- Device model
```

**Raspberry Pi**:
```bash
# OS version
cat /etc/os-release

# Pi model
cat /proc/cpuinfo | grep Model

# Memory
free -h

# Disk space
df -h

# Temperature
vcgencmd measure_temp

# Throttling status
vcgencmd get_throttled
```

### Enable Debug Logging

**iOS App**:
```swift
// Check Xcode console (Cmd+Shift+Y)
// Look for [DEBUG], [ERROR] messages
```

**Raspberry Pi**:
```bash
# Edit config.yaml
nano ~/yahboom-iphone-controller/pi/config.yaml

# Set logging level to DEBUG
logging:
  level: "DEBUG"

# Restart services
sudo systemctl restart yahboom-rtsp.service
sudo systemctl restart yahboom-motor.service

# Watch logs
tail -f /var/log/yahboom_controller.log
```

### Reset to Defaults

**iOS App**:
```
1. Delete app from iPhone
2. Reinstall from Xcode
3. All settings will be reset
```

**Raspberry Pi**:
```bash
# Restore default config
cd ~/yahboom-iphone-controller/pi
git checkout config.yaml

# Or manually edit config.yaml
```

### Complete System Restart

```bash
# Raspberry Pi
sudo reboot

# iOS App
1. Force quit app (swipe up in app switcher)
2. Wait 5 seconds
3. Relaunch app
```

## 🆘 Still Having Issues?

### Collect Diagnostic Information

**iOS**:
1. Xcode console logs (Cmd+Shift+Y)
2. Settings values (screenshot)
3. iOS version and device model

**Raspberry Pi**:
```bash
# System info
uname -a
cat /etc/os-release

# Service status
sudo systemctl status yahboom-rtsp.service
sudo systemctl status yahboom-motor.service

# Logs
sudo journalctl -u yahboom-rtsp.service -n 100
sudo journalctl -u yahboom-motor.service -n 100
tail -100 /var/log/yahboom_controller.log

# Network
ip addr
netstat -tulpn
```

### Check Documentation

1. [README.md](../README.md) - Overview and quick start
2. [SETUP_IOS.md](SETUP_IOS.md) - iOS setup details
3. [SETUP_PI.md](SETUP_PI.md) - Raspberry Pi setup details
4. [ARCHITECTURE.md](ARCHITECTURE.md) - System architecture

### Common Quick Fixes

```bash
# Raspberry Pi - Restart everything
sudo systemctl restart yahboom-rtsp.service
sudo systemctl restart yahboom-motor.service

# Raspberry Pi - Complete reboot
sudo reboot

# iOS App - Force quit and restart
# Swipe up in app switcher, then relaunch
```

---

**Most issues can be resolved by checking connections, verifying configuration, and restarting services. 🔧**
