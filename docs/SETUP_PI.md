# Raspberry Pi Setup Guide

Complete guide for setting up the Yahboom Rider Pi CM4 balancing robot with Python control scripts and RTSP video streaming.

## 📋 Prerequisites

### Hardware Requirements
- **Yahboom Rider Pi CM4 balancing robot**
- **Raspberry Pi CM4 module** (2GB+ RAM recommended)
- **Camera module** (CSI or USB camera)
- **SD card** (16GB+ recommended)
- **Power supply** for the robot
- **WiFi connectivity** or Ethernet cable

### Software Requirements
- **Raspberry Pi OS** (Bullseye or later, 64-bit recommended)
- **Python 3.8 or later**
- **SSH enabled** for remote access
- **Internet connection** for package installation

## 🔧 Initial Raspberry Pi Setup

### Step 1: Install Raspberry Pi OS

1. **Download Raspberry Pi Imager**:
   - From https://www.raspberrypi.com/software/
2. **Flash OS to SD card**:
   - Choose "Raspberry Pi OS (64-bit)"
   - Configure WiFi and SSH in advanced settings
   - Set username: `pi` and a secure password
3. **Boot the Raspberry Pi**:
   - Insert SD card and power on
   - Wait for first boot to complete (2-5 minutes)

### Step 2: Connect via SSH

From your computer:
```bash
# Find your Pi's IP address (check your router)
ssh pi@192.168.1.100  # Replace with your Pi's IP
```

### Step 3: Update the System

```bash
sudo apt update
sudo apt upgrade -y
sudo reboot
```

### Step 4: Enable Camera

```bash
# For new Raspberry Pi OS (Bullseye+)
sudo raspi-config
# Navigate to: Interface Options → Camera → Enable
# Or add to /boot/config.txt:
echo "camera_auto_detect=1" | sudo tee -a /boot/config.txt
echo "dtoverlay=imx219" | sudo tee -a /boot/config.txt  # For Pi Camera v2
sudo reboot
```

## 📦 Install Dependencies

### Step 1: Install Python Packages

```bash
# Install pip if not already installed
sudo apt install python3-pip -y

# Install system dependencies
sudo apt install python3-yaml python3-numpy -y
```

### Step 2: Install GStreamer

```bash
# Install GStreamer and plugins for RTSP streaming
sudo apt install -y \
    gstreamer1.0-tools \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-libav \
    gstreamer1.0-rtsp \
    python3-gst-1.0 \
    libgstreamer1.0-dev \
    libgstrtspserver-1.0-dev
```

### Step 3: Install Yahboom SDK (if available)

```bash
# If Yahboom provides an SDK, install it
# Check Yahboom's documentation for official SDK
# Otherwise, we'll use serial communication fallback
sudo apt install python3-serial -y
```

### Step 4: Install Additional Python Libraries

```bash
cd ~/yahboom-iphone-controller/pi
pip3 install -r requirements.txt
```

## 🚀 Project Setup

### Step 1: Clone the Repository

```bash
cd ~
git clone https://github.com/tchdvz6sp2-png/yahboom-iphone-controller.git
cd yahboom-iphone-controller/pi
```

### Step 2: Configure Settings

Edit the configuration file:
```bash
nano config.yaml
```

Update with your settings:
```yaml
# Robot connection settings
robot:
  ip_address: "192.168.1.100"  # Pi's IP address
  hostname: "yahboom-robot"

# Motor control settings
motor:
  udp_port: 5000
  serial_port: "/dev/ttyUSB0"  # Or /dev/ttyAMA0
  serial_baudrate: 115200
  max_speed: 100
  timeout: 1.0  # Emergency stop timeout in seconds

# RTSP streaming settings
rtsp:
  port: 8554
  path: "/stream"
  resolution: "640x480"  # Options: 320x240, 640x480, 1280x720
  framerate: 30
  bitrate: 2000000  # 2 Mbps

# Camera settings
camera:
  device: "/dev/video0"  # Camera device
  width: 640
  height: 480
  fps: 30

# Logging
logging:
  level: "INFO"  # DEBUG, INFO, WARNING, ERROR
  file: "/var/log/yahboom_controller.log"
```

Save with `Ctrl+X`, then `Y`, then `Enter`.

### Step 3: Set Permissions

```bash
# Allow access to serial port
sudo usermod -a -G dialout $USER
sudo usermod -a -G video $USER

# Create log directory
sudo mkdir -p /var/log
sudo chown pi:pi /var/log/yahboom_controller.log || true

# Reboot to apply group changes
sudo reboot
```

## 🧪 Testing

### Test 1: Camera Test

```bash
# Test camera with libcamera (new method)
libcamera-hello --timeout 5000

# Or test with GStreamer
gst-launch-1.0 libcamerasrc ! videoconvert ! autovideosink
```

If the camera preview appears, camera is working correctly.

### Test 2: Motor Control Test

```bash
cd ~/yahboom-iphone-controller/pi
python3 test_motors.py
```

Expected output:
```
Testing motor control...
Forward... OK
Backward... OK
Left turn... OK
Right turn... OK
Stop... OK
All motor tests passed!
```

### Test 3: RTSP Streaming Test

In one terminal:
```bash
cd ~/yahboom-iphone-controller/pi
python3 rtsp_server.py
```

Expected output:
```
Starting RTSP server on rtsp://192.168.1.100:8554/stream
Server ready. Press Ctrl+C to stop.
```

In another terminal or on your computer:
```bash
# Test with VLC or ffplay
ffplay rtsp://192.168.1.100:8554/stream
# Or
vlc rtsp://192.168.1.100:8554/stream
```

You should see the camera feed.

### Test 4: Full System Test

```bash
cd ~/yahboom-iphone-controller/pi
python3 test_streaming.py
```

## 🏃 Running the System

### Option 1: Manual Start

Start each component in a separate terminal:

**Terminal 1 - RTSP Server:**
```bash
cd ~/yahboom-iphone-controller/pi
python3 rtsp_server.py
```

**Terminal 2 - Motor Controller:**
```bash
cd ~/yahboom-iphone-controller/pi
python3 motor_controller.py
```

### Option 2: Using systemd (Auto-start on Boot)

Create service files:

**RTSP Server Service:**
```bash
sudo nano /etc/systemd/system/yahboom-rtsp.service
```

Add:
```ini
[Unit]
Description=Yahboom RTSP Streaming Server
After=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/yahboom-iphone-controller/pi
ExecStart=/usr/bin/python3 /home/pi/yahboom-iphone-controller/pi/rtsp_server.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

**Motor Controller Service:**
```bash
sudo nano /etc/systemd/system/yahboom-motor.service
```

Add:
```ini
[Unit]
Description=Yahboom Motor Controller
After=network.target yahboom-rtsp.service

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/yahboom-iphone-controller/pi
ExecStart=/usr/bin/python3 /home/pi/yahboom-iphone-controller/pi/motor_controller.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Enable and start services:
```bash
sudo systemctl daemon-reload
sudo systemctl enable yahboom-rtsp.service
sudo systemctl enable yahboom-motor.service
sudo systemctl start yahboom-rtsp.service
sudo systemctl start yahboom-motor.service
```

Check status:
```bash
sudo systemctl status yahboom-rtsp.service
sudo systemctl status yahboom-motor.service
```

### Option 3: Using tmux for Easy Management

```bash
# Install tmux
sudo apt install tmux -y

# Create startup script
nano ~/start_yahboom.sh
```

Add:
```bash
#!/bin/bash
cd ~/yahboom-iphone-controller/pi

# Create new tmux session
tmux new-session -d -s yahboom

# Start RTSP server in first window
tmux send-keys "python3 rtsp_server.py" C-m

# Create new window for motor controller
tmux new-window -t yahboom:1
tmux send-keys "python3 motor_controller.py" C-m

# Attach to session
tmux attach -t yahboom
```

Make executable:
```bash
chmod +x ~/start_yahboom.sh
```

Run:
```bash
~/start_yahboom.sh
```

Use `Ctrl+B` then `D` to detach, `tmux attach -t yahboom` to reattach.

## 🔍 Monitoring and Logs

### View Real-time Logs

```bash
# RTSP server logs
sudo journalctl -u yahboom-rtsp.service -f

# Motor controller logs
sudo journalctl -u yahboom-motor.service -f

# Or check log file
tail -f /var/log/yahboom_controller.log
```

### Check Network Status

```bash
# Check IP address
hostname -I

# Test network connectivity
ping 8.8.8.8

# Check open ports
sudo netstat -tulpn | grep python
```

### Monitor System Resources

```bash
# CPU and memory usage
htop

# Or simpler
top

# Temperature
vcgencmd measure_temp

# Camera status
vcgencmd get_camera
```

## 🐛 Troubleshooting

### Camera Not Working

**Problem**: No camera detected
**Solution**:
```bash
# Check camera connection
vcgencmd get_camera

# Should show: supported=1 detected=1

# Test camera
libcamera-hello --list-cameras
libcamera-hello --timeout 5000

# Check /boot/config.txt
sudo nano /boot/config.txt
# Ensure: camera_auto_detect=1
```

### RTSP Stream Not Accessible

**Problem**: Can't connect to RTSP stream
**Solution**:
```bash
# Check if server is running
sudo netstat -tulpn | grep 8554

# Check firewall
sudo ufw status
sudo ufw allow 8554/tcp

# Test locally
gst-launch-1.0 rtspsrc location=rtsp://localhost:8554/stream ! fakesink

# Check logs
tail -f /var/log/yahboom_controller.log
```

### Motor Control Not Working

**Problem**: Motors don't respond to commands
**Solution**:
```bash
# Check serial port
ls -l /dev/ttyUSB* /dev/ttyAMA*

# Check permissions
groups  # Should include 'dialout'

# Test serial connection
python3 -c "import serial; print(serial.__version__)"

# Check motor controller logs
sudo journalctl -u yahboom-motor.service -f
```

### High CPU Usage

**Problem**: Raspberry Pi running hot/slow
**Solution**:
```bash
# Check temperature
vcgencmd measure_temp

# Reduce video resolution in config.yaml
nano config.yaml
# Change resolution to 320x240

# Lower framerate
# Change framerate to 15

# Check running processes
htop

# Consider adding heatsink/fan if temp > 70°C
```

### Connection Timeouts

**Problem**: iOS app can't connect
**Solution**:
```bash
# Check SSH is running
sudo systemctl status ssh

# Enable SSH if needed
sudo systemctl enable ssh
sudo systemctl start ssh

# Check firewall
sudo ufw status
sudo ufw allow 22/tcp
sudo ufw allow 5000/udp
sudo ufw allow 8554/tcp
```

## 🔒 Security Hardening

### Change Default Passwords

```bash
# Change pi user password
passwd
```

### Configure Firewall

```bash
# Install UFW
sudo apt install ufw -y

# Set defaults
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH
sudo ufw allow 22/tcp

# Allow RTSP
sudo ufw allow 8554/tcp

# Allow motor control
sudo ufw allow 5000/udp

# Enable firewall
sudo ufw enable
```

### Use SSH Keys Instead of Passwords

On your computer:
```bash
# Generate key
ssh-keygen -t ed25519

# Copy to Pi
ssh-copy-id pi@192.168.1.100
```

On Pi:
```bash
# Disable password auth (optional)
sudo nano /etc/ssh/sshd_config
# Set: PasswordAuthentication no
sudo systemctl restart ssh
```

## 📊 Performance Optimization

### Overclock (Carefully)

Edit `/boot/config.txt`:
```bash
sudo nano /boot/config.txt
```

Add:
```
# Mild overclock
arm_freq=1800
gpu_freq=600
over_voltage=2
```

Reboot and test stability.

### Optimize Video Encoding

In `config.yaml`, experiment with:
```yaml
rtsp:
  resolution: "320x240"  # Lower resolution = lower latency
  framerate: 24          # 24 fps instead of 30
  bitrate: 1000000       # 1 Mbps instead of 2
```

### Reduce Services

```bash
# Disable Bluetooth if not needed
sudo systemctl disable bluetooth
sudo systemctl disable hciuart

# Disable WiFi if using Ethernet
sudo systemctl disable wpa_supplicant
```

## 🔄 Updates and Maintenance

### Update the Project

```bash
cd ~/yahboom-iphone-controller
git pull origin main

# Restart services
sudo systemctl restart yahboom-rtsp.service
sudo systemctl restart yahboom-motor.service
```

### Update System Packages

```bash
sudo apt update
sudo apt upgrade -y
sudo reboot
```

### Backup Configuration

```bash
# Backup config
cp ~/yahboom-iphone-controller/pi/config.yaml ~/config.yaml.backup

# Restore if needed
cp ~/config.yaml.backup ~/yahboom-iphone-controller/pi/config.yaml
```

## 📝 Advanced Configuration

### Using Different Camera

For USB cameras:
```yaml
camera:
  device: "/dev/video0"  # Check with: ls /dev/video*
```

For CSI camera (alternative pipeline):
```bash
# Test CSI camera
libcamera-vid -t 0 --inline --listen -o tcp://0.0.0.0:8888
```

### Custom Motor Commands

Edit `motor_controller.py` to customize motor behavior:
- Adjust speed curves
- Add acceleration limiting
- Implement PID control
- Add sensor integration

### Network Optimization

For lowest latency:
```bash
# Use 5GHz WiFi
sudo raspi-config
# System Options → Wireless LAN → Set up 5GHz

# Or configure static IP
sudo nano /etc/dhcpcd.conf
# Add:
# interface wlan0
# static ip_address=192.168.1.100/24
# static routers=192.168.1.1
# static domain_name_servers=8.8.8.8
```

## 🆘 Getting Help

Check logs:
```bash
sudo journalctl -u yahboom-rtsp.service --since "10 minutes ago"
sudo journalctl -u yahboom-motor.service --since "10 minutes ago"
tail -f /var/log/yahboom_controller.log
```

Common commands:
```bash
# Restart services
sudo systemctl restart yahboom-rtsp.service yahboom-motor.service

# Stop services
sudo systemctl stop yahboom-rtsp.service yahboom-motor.service

# View status
sudo systemctl status yahboom-rtsp.service
sudo systemctl status yahboom-motor.service
```

---

**Happy building! 🤖**
