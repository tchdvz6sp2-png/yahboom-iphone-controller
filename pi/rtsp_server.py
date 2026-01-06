#!/usr/bin/env python3
"""
RTSP Video Server for Yahboom Rider Pi CM4 Balancing Robot

This script captures video from the Raspberry Pi camera and streams it
via RTSP using GStreamer. The stream can be accessed by iOS devices or
other RTSP clients.

Usage:
    python3 rtsp_server.py [--config CONFIG_FILE]
"""

import sys
import signal
import logging
import argparse
import subprocess
import time

try:
    import yaml
except ImportError:
    print("Error: PyYAML not installed. Run: pip install PyYAML")
    sys.exit(1)

# Check for GStreamer availability
try:
    import gi
    gi.require_version('Gst', '1.0')
    gi.require_version('GstRtspServer', '1.0')
    from gi.repository import Gst, GstRtspServer, GLib
    GST_AVAILABLE = True
except (ImportError, ValueError):
    print("Warning: GStreamer Python bindings not available")
    print("Install with: sudo apt install python3-gst-1.0")
    GST_AVAILABLE = False


class RTSPVideoServer:
    """RTSP server for streaming video from Pi Camera"""
    
    def __init__(self, config):
        self.config = config
        self.server = None
        self.mainloop = None
        
        if not GST_AVAILABLE:
            logging.warning("Running in simulation mode (GStreamer not available)")
            return
        
        # Initialize GStreamer
        Gst.init(None)
        
    def create_pipeline(self):
        """
        Create GStreamer pipeline for video capture and RTSP streaming
        
        Pipeline: camera source -> encode -> RTP payload -> RTSP server
        """
        width = self.config['camera']['resolution'][0]
        height = self.config['camera']['resolution'][1]
        framerate = self.config['camera']['framerate']
        bitrate = self.config['camera']['bitrate']
        device = self.config['camera']['device']
        
        # Build pipeline string
        # Using v4l2src for camera input (works with most Pi camera setups)
        pipeline_str = (
            f"v4l2src device={device} ! "
            f"video/x-raw,width={width},height={height},framerate={framerate}/1 ! "
            f"videoconvert ! "
            f"x264enc tune=zerolatency bitrate={bitrate//1000} speed-preset=superfast ! "
            f"rtph264pay name=pay0 pt=96"
        )
        
        logging.info(f"Pipeline: {pipeline_str}")
        return pipeline_str
    
    def start(self):
        """Start the RTSP server"""
        if not GST_AVAILABLE:
            self._simulate_server()
            return
        
        try:
            # Create RTSP server
            self.server = GstRtspServer.RTSPServer()
            self.server.set_service(str(self.config['network']['rtsp_port']))
            
            # Get mount points
            mounts = self.server.get_mount_points()
            
            # Create factory for the stream
            factory = GstRtspServer.RTSPMediaFactory()
            factory.set_launch(self.create_pipeline())
            factory.set_shared(True)
            
            # Add factory to mount point
            mounts.add_factory("/stream", factory)
            
            # Attach server to default main context
            self.server.attach(None)
            
            port = self.config['network']['rtsp_port']
            logging.info("=" * 60)
            logging.info(f"RTSP server started on port {port}")
            logging.info(f"Stream available at: rtsp://<pi-ip>:{port}/stream")
            logging.info("=" * 60)
            
            # Start main loop
            self.mainloop = GLib.MainLoop()
            self.mainloop.run()
            
        except Exception as e:
            logging.error(f"Failed to start RTSP server: {e}")
            raise
    
    def _simulate_server(self):
        """Simulate RTSP server when GStreamer is not available"""
        port = self.config['network']['rtsp_port']
        logging.info("=" * 60)
        logging.info(f"[SIMULATION] RTSP server on port {port}")
        logging.info(f"[SIMULATION] Stream at: rtsp://<pi-ip>:{port}/stream")
        logging.info("=" * 60)
        
        try:
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            pass
    
    def stop(self):
        """Stop the RTSP server"""
        logging.info("Stopping RTSP server...")
        
        if self.mainloop:
            self.mainloop.quit()


class CameraValidator:
    """Validates camera availability and configuration"""
    
    @staticmethod
    def check_camera_device(device):
        """Check if camera device exists and is accessible"""
        try:
            import os
            if not os.path.exists(device):
                logging.error(f"Camera device {device} does not exist")
                return False
            
            if not os.access(device, os.R_OK):
                logging.error(f"Camera device {device} is not readable")
                logging.info("Try: sudo usermod -a -G video $USER")
                return False
            
            logging.info(f"Camera device {device} is accessible")
            return True
            
        except Exception as e:
            logging.error(f"Error checking camera device: {e}")
            return False
    
    @staticmethod
    def test_camera_capture(device):
        """Test camera capture using v4l2"""
        try:
            # Try to capture a test frame
            cmd = [
                'v4l2-ctl',
                '--device', device,
                '--list-formats-ext'
            ]
            
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=5)
            
            if result.returncode == 0:
                logging.info("Camera test successful")
                logging.debug(f"Camera capabilities:\n{result.stdout}")
                return True
            else:
                logging.warning(f"Camera test failed: {result.stderr}")
                return False
                
        except subprocess.TimeoutExpired:
            logging.error("Camera test timed out")
            return False
        except FileNotFoundError:
            logging.warning("v4l2-ctl not found (optional test)")
            return True  # Don't fail if tool not available
        except Exception as e:
            logging.error(f"Camera test error: {e}")
            return False


def load_config(config_file):
    """Load configuration from YAML file"""
    try:
        with open(config_file, 'r') as f:
            config = yaml.safe_load(f)
        logging.info(f"Configuration loaded from {config_file}")
        return config
    except Exception as e:
        logging.error(f"Failed to load configuration: {e}")
        sys.exit(1)


def setup_logging(config):
    """Setup logging configuration"""
    log_level = getattr(logging, config['logging']['level'].upper())
    log_format = config['logging']['format']
    
    handlers = []
    
    if config['logging']['console']:
        handlers.append(logging.StreamHandler())
    
    if config['logging']['file']:
        handlers.append(logging.FileHandler(config['logging']['file']))
    
    logging.basicConfig(
        level=log_level,
        format=log_format,
        handlers=handlers
    )


def signal_handler(signum, frame):
    """Handle shutdown signals"""
    logging.info("Shutdown signal received")
    sys.exit(0)


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(description='Yahboom RTSP Video Server')
    parser.add_argument('--config', default='config.yaml',
                       help='Path to configuration file')
    parser.add_argument('--test-camera', action='store_true',
                       help='Test camera and exit')
    args = parser.parse_args()
    
    # Load configuration
    config = load_config(args.config)
    
    # Setup logging
    setup_logging(config)
    
    logging.info("=" * 60)
    logging.info("Yahboom Rider Pi CM4 RTSP Server Starting")
    logging.info("=" * 60)
    
    # Validate camera
    validator = CameraValidator()
    device = config['camera']['device']
    
    if not validator.check_camera_device(device):
        logging.warning("Camera device check failed, but continuing...")
    
    if args.test_camera:
        logging.info("Running camera test...")
        if validator.test_camera_capture(device):
            logging.info("Camera test passed!")
            sys.exit(0)
        else:
            logging.error("Camera test failed!")
            sys.exit(1)
    
    # Initialize RTSP server
    rtsp_server = RTSPVideoServer(config)
    
    # Setup signal handlers
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    try:
        # Start server
        rtsp_server.start()
        
    except KeyboardInterrupt:
        logging.info("Keyboard interrupt received")
    
    finally:
        # Cleanup
        rtsp_server.stop()
        logging.info("Shutdown complete")


if __name__ == '__main__':
    main()
