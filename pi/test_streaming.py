#!/usr/bin/env python3
"""
RTSP Streaming Test Script for Yahboom Rider Pi CM4 Robot

This script tests the RTSP video streaming by checking if the stream
is accessible and provides instructions for testing with external tools.

Usage:
    python3 test_streaming.py
"""

import sys
import time
import socket
from pathlib import Path
import yaml


def load_config(config_path='config.yaml'):
    """Load configuration from YAML file"""
    try:
        with open(config_path, 'r') as f:
            return yaml.safe_load(f)
    except Exception as e:
        print(f"Error loading config: {e}")
        return None


def check_port_open(host, port, timeout=2):
    """
    Check if a TCP port is open
    
    Args:
        host: Hostname or IP address
        port: Port number
        timeout: Connection timeout in seconds
        
    Returns:
        True if port is open, False otherwise
    """
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(timeout)
        result = sock.connect_ex((host, port))
        sock.close()
        return result == 0
    except Exception as e:
        print(f"Error checking port: {e}")
        return False


def test_rtsp_server():
    """Test RTSP server accessibility"""
    print("=" * 60)
    print("Yahboom Robot RTSP Streaming Test")
    print("=" * 60)
    
    # Load config
    config_path = Path(__file__).parent / 'config.yaml'
    config = load_config(str(config_path))
    
    if not config:
        print("Failed to load configuration. Using defaults.")
        port = 8554
        host = 'localhost'
        path = '/stream'
    else:
        port = config['rtsp']['port']
        path = config['rtsp']['path']
        host = config['robot'].get('ip_address', 'localhost')
        if host in ['0.0.0.0', '']:
            # Get actual IP if bound to all interfaces
            try:
                # Try to get hostname
                hostname = socket.gethostname()
                host = socket.gethostbyname(hostname)
            except:
                host = 'localhost'
    
    rtsp_url = f"rtsp://{host}:{port}{path}"
    
    print(f"\nRTSP Server Configuration:")
    print(f"  Host: {host}")
    print(f"  Port: {port}")
    print(f"  Path: {path}")
    print(f"  Full URL: {rtsp_url}")
    
    # Check if RTSP port is open
    print(f"\nChecking if RTSP server is running on port {port}...")
    
    if check_port_open(host, port):
        print(f"✓ RTSP server appears to be running on port {port}")
    else:
        print(f"✗ Cannot connect to port {port}")
        print("\nTroubleshooting:")
        print("1. Ensure rtsp_server.py is running")
        print("2. Check firewall settings (allow TCP port {})".format(port))
        print("3. Verify IP address and port in config.yaml")
        return False
    
    # Provide testing instructions
    print("\n" + "=" * 60)
    print("Stream Testing Instructions")
    print("=" * 60)
    
    print("\nThe RTSP server appears to be running.")
    print("To verify video streaming, use one of these methods:\n")
    
    print("1. VLC Media Player:")
    print(f"   vlc {rtsp_url}")
    print("   Or: Media → Open Network Stream → Enter URL\n")
    
    print("2. FFplay (part of FFmpeg):")
    print(f"   ffplay -rtsp_transport tcp {rtsp_url}\n")
    
    print("3. GStreamer:")
    print(f"   gst-launch-1.0 rtspsrc location={rtsp_url} ! decodebin ! autovideosink\n")
    
    print("4. iOS App:")
    print(f"   Enter '{rtsp_url}' in Settings → RTSP URL")
    print("   Then connect to the robot\n")
    
    # Camera check
    print("=" * 60)
    print("Camera Check")
    print("=" * 60)
    
    print("\nTo verify your camera is working:")
    print("1. libcamera (newer Raspberry Pi OS):")
    print("   libcamera-hello --timeout 5000")
    print("   libcamera-still -o test.jpg")
    
    print("\n2. Legacy camera tools:")
    print("   raspistill -o test.jpg")
    
    print("\n3. Check camera detection:")
    print("   vcgencmd get_camera")
    print("   Should show: supported=1 detected=1")
    
    # Resolution info
    if config:
        camera_config = config.get('camera', {})
        rtsp_config = config.get('rtsp', {})
        
        print("\n" + "=" * 60)
        print("Current Stream Configuration")
        print("=" * 60)
        print(f"Resolution: {camera_config.get('width', 640)}x{camera_config.get('height', 480)}")
        print(f"Framerate: {camera_config.get('fps', 30)} FPS")
        print(f"Bitrate: {rtsp_config.get('bitrate', 2000000) // 1000000} Mbps")
        print(f"Encoding: H.264 (zerolatency)")
        
        print("\nTo change settings, edit config.yaml and restart rtsp_server.py")
    
    return True


def test_camera_device():
    """Test if camera device is accessible"""
    print("\n" + "=" * 60)
    print("Camera Device Check")
    print("=" * 60)
    
    # Load config
    config_path = Path(__file__).parent / 'config.yaml'
    config = load_config(str(config_path))
    
    if not config:
        return
    
    camera_type = config.get('camera', {}).get('type', 'libcamera')
    
    if camera_type == 'libcamera':
        print("\nCamera type: libcamera (CSI camera)")
        print("\nTo test the camera:")
        print("  libcamera-hello --list-cameras")
        print("  libcamera-hello --timeout 5000")
        
    else:
        # v4l2 device
        device = config.get('camera', {}).get('device', '/dev/video0')
        print(f"\nCamera type: v4l2")
        print(f"Device: {device}")
        
        # Check if device exists
        if Path(device).exists():
            print(f"✓ Camera device {device} exists")
        else:
            print(f"✗ Camera device {device} not found")
            print("\nAvailable video devices:")
            import subprocess
            try:
                result = subprocess.run(['ls', '-l', '/dev/video*'], 
                                      capture_output=True, text=True)
                if result.returncode == 0:
                    print(result.stdout)
                else:
                    print("No video devices found")
            except:
                pass


def main():
    """Main entry point"""
    print("\n" + "=" * 60)
    print("YAHBOOM ROBOT RTSP STREAMING TEST")
    print("=" * 60)
    
    # Test RTSP server
    server_ok = test_rtsp_server()
    
    # Test camera device
    test_camera_device()
    
    # Summary
    print("\n" + "=" * 60)
    print("Test Summary")
    print("=" * 60)
    
    if server_ok:
        print("\n✓ RTSP server is accessible")
        print("\nNext steps:")
        print("1. Test the stream with VLC or ffplay")
        print("2. Verify video quality and latency")
        print("3. Connect from the iOS app")
    else:
        print("\n✗ RTSP server is not accessible")
        print("\nPlease:")
        print("1. Start rtsp_server.py: python3 rtsp_server.py")
        print("2. Check for any error messages")
        print("3. Verify camera is working")
        print("4. Run this test again")
    
    print("\n" + "=" * 60)
    
    return 0 if server_ok else 1


if __name__ == '__main__':
    sys.exit(main())
