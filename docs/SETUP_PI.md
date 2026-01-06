# Raspberry Pi Setup Guide

This guide covers the complete setup process for running the Yahboom Rider Pi CM4 balancing robot control scripts.

## Prerequisites

- Yahboom Rider Pi CM4 balancing robot with Raspberry Pi CM4
- Raspberry Pi OS (Bullseye or later) installed
- Python 3.8 or higher
- Network connectivity (WiFi or Ethernet)
- SSH access enabled

## Hardware Setup

1. **Assemble the Robot**
   - Follow Yahboom's assembly instructions for the Rider Pi CM4
   - Ensure all motor connections are secure
   - Verify power supply is properly connected

2. **Enable Raspberry Pi Camera**
   ```bash
   sudo raspi-config
   # Navigate to Interface Options -> Camera -> Enable
   ```

3. **Enable I2C for Motor Control** (if not already enabled)
   ```bash
   sudo raspi-config
   # Navigate to Interface Options -> I2C -> Enable
   ```

## Software Installation

### 1. Update System Packages

```bash
sudo apt update
sudo apt upgrade -y
```

### 2. Install GStreamer (for video streaming)

```bash
sudo apt install -y gstreamer1.0-tools gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly gstreamer1.0-libav \
    gstreamer1.0-rtsp python3-gst-1.0
```

### 3. Install Python Dependencies

```bash
cd ~/yahboom-iphone-controller/pi
pip3 install -r requirements.txt
```

### 4. Configure Settings

Edit `config.yaml` with your specific settings:

```bash
nano config.yaml
```

Key configuration parameters:
- `motor_udp_port`: UDP port for receiving motor commands (default: 5005)
- `rtsp_port`: RTSP streaming port (default: 8554)
- `camera_resolution`: Camera resolution (default: 640x480)
- `camera_framerate`: Camera framerate (default: 30)
- `motor_speed_limit`: Maximum motor speed (0-100)

## Running the Scripts

### Start Motor Controller

```bash
python3 motor_controller.py
```

The motor controller will:
- Listen for UDP commands on the configured port
- Process joystick input and control motors accordingly
- Provide feedback on motor status

### Start RTSP Video Server

```bash
python3 rtsp_server.py
```

The RTSP server will:
- Capture video from the Pi camera
- Stream via RTSP on the configured port
- Be accessible at `rtsp://<pi-ip-address>:8554/stream`

### Run Both Services at Startup (Optional)

Create systemd service files to auto-start services:

1. **Motor Controller Service**

```bash
sudo nano /etc/systemd/system/yahboom-motor.service
```

Add:
```ini
[Unit]
Description=Yahboom Motor Controller
After=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/yahboom-iphone-controller/pi
ExecStart=/usr/bin/python3 motor_controller.py
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

2. **RTSP Server Service**

```bash
sudo nano /etc/systemd/system/yahboom-rtsp.service
```

Add:
```ini
[Unit]
Description=Yahboom RTSP Server
After=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/yahboom-iphone-controller/pi
ExecStart=/usr/bin/python3 rtsp_server.py
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

3. **Enable and Start Services**

```bash
sudo systemctl daemon-reload
sudo systemctl enable yahboom-motor.service
sudo systemctl enable yahboom-rtsp.service
sudo systemctl start yahboom-motor.service
sudo systemctl start yahboom-rtsp.service
```

## Testing

### Test Motor Control

```bash
python3 test_motors.py
```

This will:
- Verify motor connections
- Test basic movement commands
- Check motor response times

### Test Video Streaming

```bash
python3 test_streaming.py
```

This will:
- Verify camera functionality
- Test GStreamer pipeline
- Check RTSP stream availability

### Manual RTSP Stream Test

From another device on the same network:

```bash
# Using VLC
vlc rtsp://<pi-ip-address>:8554/stream

# Using ffplay
ffplay rtsp://<pi-ip-address>:8554/stream

# Using GStreamer
gst-launch-1.0 playbin uri=rtsp://<pi-ip-address>:8554/stream
```

## Network Configuration

### Find Your Pi's IP Address

```bash
hostname -I
```

### Configure Static IP (Recommended)

Edit `/etc/dhcpcd.conf`:

```bash
sudo nano /etc/dhcpcd.conf
```

Add:
```
interface wlan0
static ip_address=192.168.1.100/24
static routers=192.168.1.1
static domain_name_servers=192.168.1.1 8.8.8.8
```

Restart networking:
```bash
sudo systemctl restart dhcpcd
```

## Firewall Configuration

If you have a firewall enabled:

```bash
sudo ufw allow 5005/udp  # Motor control
sudo ufw allow 8554/tcp  # RTSP streaming
sudo ufw allow 22/tcp    # SSH
```

## Performance Optimization

### Overclock (Optional, for better performance)

Edit `/boot/config.txt`:
```bash
sudo nano /boot/config.txt
```

Add:
```
over_voltage=2
arm_freq=1500
```

**Warning**: Overclocking may void warranty and requires adequate cooling.

### Disable Desktop Environment (for headless operation)

```bash
sudo systemctl set-default multi-user.target
```

## Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues and solutions.

## Next Steps

- Configure iOS application to connect to your Pi's IP address
- Test the complete system end-to-end
- Fine-tune motor control parameters in `config.yaml`
- Adjust camera settings for optimal video quality
