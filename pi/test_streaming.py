#!/usr/bin/env python3
"""
Video Streaming Test Script for Yahboom Rider Pi CM4

This script tests the camera and RTSP streaming setup by validating
camera availability, GStreamer installation, and stream accessibility.

Usage:
    python3 test_streaming.py [--config CONFIG_FILE]
"""

import sys
import subprocess
import time
import argparse
import os

try:
    import yaml
except ImportError:
    print("Error: PyYAML not installed. Run: pip install PyYAML")
    sys.exit(1)


class StreamingTester:
    """Test harness for video streaming"""
    
    def __init__(self, config):
        self.config = config
        self.device = config['camera']['device']
        self.port = config['network']['rtsp_port']
    
    def test_camera_device(self):
        """Test 1: Check if camera device exists"""
        print("\n--- Test 1: Camera Device Existence ---")
        
        if os.path.exists(self.device):
            print(f"✓ Camera device {self.device} exists")
            
            if os.access(self.device, os.R_OK):
                print(f"✓ Camera device is readable")
                return True
            else:
                print(f"✗ Camera device is not readable")
                print("  Try: sudo usermod -a -G video $USER")
                return False
        else:
            print(f"✗ Camera device {self.device} not found")
            print("  Check if camera is properly connected")
            print("  Try: ls -l /dev/video*")
            return False
    
    def test_v4l2_tools(self):
        """Test 2: Check v4l2 tools and camera capabilities"""
        print("\n--- Test 2: V4L2 Camera Capabilities ---")
        
        try:
            result = subprocess.run(
                ['v4l2-ctl', '--device', self.device, '--list-formats-ext'],
                capture_output=True,
                text=True,
                timeout=5
            )
            
            if result.returncode == 0:
                print("✓ v4l2-ctl working")
                print("\nSupported formats:")
                print(result.stdout)
                return True
            else:
                print(f"✗ v4l2-ctl failed: {result.stderr}")
                return False
                
        except FileNotFoundError:
            print("⚠ v4l2-ctl not found (install with: sudo apt install v4l-utils)")
            print("  Continuing without detailed camera info...")
            return True
        except subprocess.TimeoutExpired:
            print("✗ v4l2-ctl timed out")
            return False
        except Exception as e:
            print(f"✗ Error: {e}")
            return False
    
    def test_gstreamer(self):
        """Test 3: Check GStreamer installation"""
        print("\n--- Test 3: GStreamer Installation ---")
        
        try:
            result = subprocess.run(
                ['gst-inspect-1.0', '--version'],
                capture_output=True,
                text=True,
                timeout=5
            )
            
            if result.returncode == 0:
                print("✓ GStreamer installed")
                print(result.stdout.strip())
                return True
            else:
                print("✗ GStreamer not working properly")
                return False
                
        except FileNotFoundError:
            print("✗ GStreamer not found")
            print("  Install with: sudo apt install gstreamer1.0-tools")
            return False
        except Exception as e:
            print(f"✗ Error: {e}")
            return False
    
    def test_gstreamer_plugins(self):
        """Test 4: Check required GStreamer plugins"""
        print("\n--- Test 4: GStreamer Plugins ---")
        
        required_plugins = [
            'v4l2src',
            'videoconvert',
            'x264enc',
            'rtph264pay'
        ]
        
        all_found = True
        
        for plugin in required_plugins:
            try:
                result = subprocess.run(
                    ['gst-inspect-1.0', plugin],
                    capture_output=True,
                    timeout=5
                )
                
                if result.returncode == 0:
                    print(f"✓ Plugin '{plugin}' available")
                else:
                    print(f"✗ Plugin '{plugin}' not found")
                    all_found = False
                    
            except Exception as e:
                print(f"✗ Error checking plugin '{plugin}': {e}")
                all_found = False
        
        if not all_found:
            print("\n  Install missing plugins with:")
            print("  sudo apt install gstreamer1.0-plugins-good")
            print("  sudo apt install gstreamer1.0-plugins-bad")
            print("  sudo apt install gstreamer1.0-plugins-ugly")
        
        return all_found
    
    def test_camera_capture(self):
        """Test 5: Test camera capture with GStreamer"""
        print("\n--- Test 5: Camera Capture Test ---")
        print("Testing camera capture for 3 seconds...")
        
        try:
            # Simple pipeline that captures and discards video
            cmd = [
                'gst-launch-1.0',
                '-e',
                'v4l2src', f'device={self.device}',
                '!', 'video/x-raw,width=640,height=480',
                '!', 'fakesink'
            ]
            
            process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )
            
            # Let it run for 3 seconds
            time.sleep(3)
            process.terminate()
            
            try:
                process.wait(timeout=2)
            except subprocess.TimeoutExpired:
                process.kill()
            
            if process.returncode in [0, -15]:  # 0 or SIGTERM
                print("✓ Camera capture successful")
                return True
            else:
                print("✗ Camera capture failed")
                return False
                
        except FileNotFoundError:
            print("✗ gst-launch-1.0 not found")
            return False
        except Exception as e:
            print(f"✗ Error: {e}")
            return False
    
    def test_encoding_pipeline(self):
        """Test 6: Test full encoding pipeline"""
        print("\n--- Test 6: H.264 Encoding Pipeline ---")
        print("Testing encoding pipeline for 3 seconds...")
        
        width = self.config['camera']['resolution'][0]
        height = self.config['camera']['resolution'][1]
        
        try:
            cmd = [
                'gst-launch-1.0',
                '-e',
                'v4l2src', f'device={self.device}',
                '!', f'video/x-raw,width={width},height={height}',
                '!', 'videoconvert',
                '!', 'x264enc', 'tune=zerolatency', 'bitrate=2000',
                '!', 'fakesink'
            ]
            
            process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )
            
            time.sleep(3)
            process.terminate()
            
            try:
                process.wait(timeout=2)
            except subprocess.TimeoutExpired:
                process.kill()
            
            if process.returncode in [0, -15]:
                print("✓ Encoding pipeline successful")
                return True
            else:
                print("✗ Encoding pipeline failed")
                return False
                
        except Exception as e:
            print(f"✗ Error: {e}")
            return False
    
    def test_rtsp_port(self):
        """Test 7: Check if RTSP port is available"""
        print("\n--- Test 7: RTSP Port Availability ---")
        
        try:
            result = subprocess.run(
                ['netstat', '-tuln'],
                capture_output=True,
                text=True,
                timeout=5
            )
            
            if f":{self.port}" in result.stdout:
                print(f"⚠ Port {self.port} is already in use")
                print("  RTSP server may already be running")
                print("  Or another service is using this port")
                return False
            else:
                print(f"✓ Port {self.port} is available")
                return True
                
        except FileNotFoundError:
            print("⚠ netstat not found (continuing anyway)")
            return True
        except Exception as e:
            print(f"⚠ Error checking port: {e}")
            return True
    
    def run_all_tests(self):
        """Run all streaming tests"""
        print("=" * 60)
        print("Video Streaming Test Suite")
        print("=" * 60)
        print(f"\nConfiguration:")
        print(f"  Camera device: {self.device}")
        print(f"  Resolution: {self.config['camera']['resolution']}")
        print(f"  Framerate: {self.config['camera']['framerate']}")
        print(f"  RTSP port: {self.port}")
        
        tests = [
            ("Camera Device", self.test_camera_device),
            ("V4L2 Capabilities", self.test_v4l2_tools),
            ("GStreamer", self.test_gstreamer),
            ("GStreamer Plugins", self.test_gstreamer_plugins),
            ("Camera Capture", self.test_camera_capture),
            ("Encoding Pipeline", self.test_encoding_pipeline),
            ("RTSP Port", self.test_rtsp_port),
        ]
        
        results = []
        
        for name, test in tests:
            try:
                result = test()
                results.append((name, result))
            except KeyboardInterrupt:
                print("\n\nTests interrupted by user")
                break
            except Exception as e:
                print(f"✗ Test '{name}' failed with error: {e}")
                results.append((name, False))
        
        # Summary
        print("\n" + "=" * 60)
        print("Test Summary")
        print("=" * 60)
        
        passed = sum(1 for _, result in results if result)
        total = len(results)
        
        for name, result in results:
            status = "✓ PASS" if result else "✗ FAIL"
            print(f"{status}: {name}")
        
        print("\n" + "=" * 60)
        print(f"Results: {passed}/{total} tests passed")
        print("=" * 60)
        
        if passed == total:
            print("\n✓ All tests passed! Ready to start RTSP server.")
            return True
        else:
            print("\n⚠ Some tests failed. Review errors above.")
            return False


def load_config(config_file):
    """Load configuration from YAML file"""
    try:
        with open(config_file, 'r') as f:
            return yaml.safe_load(f)
    except Exception as e:
        print(f"Error loading config: {e}")
        sys.exit(1)


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(description='Test Video Streaming')
    parser.add_argument('--config', default='config.yaml',
                       help='Path to configuration file')
    args = parser.parse_args()
    
    # Load configuration
    config = load_config(args.config)
    
    # Create tester
    tester = StreamingTester(config)
    
    # Run tests
    success = tester.run_all_tests()
    
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()
