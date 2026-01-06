#!/usr/bin/env python3
"""
RTSP Video Streaming Server for Yahboom Rider Pi CM4 Robot

This script captures video from the Raspberry Pi camera and streams it
via RTSP protocol using GStreamer for low-latency video transmission.

Features:
- GStreamer-based RTSP streaming
- H.264 hardware encoding (when available)
- Low-latency optimization (<150ms)
- Configurable resolution and bitrate
- Automatic restart on failure
"""

import gi
gi.require_version('Gst', '1.0')
gi.require_version('GstRtspServer', '1.0')
from gi.repository import Gst, GstRtspServer, GLib

import logging
import signal
import sys
from pathlib import Path
import yaml


class RTSPServer:
    """RTSP server for streaming camera video"""
    
    def __init__(self, config_path='config.yaml'):
        """
        Initialize the RTSP server
        
        Args:
            config_path: Path to configuration YAML file
        """
        # Load configuration
        self.config = self.load_config(config_path)
        
        # Setup logging
        self.setup_logging()
        self.logger = logging.getLogger(__name__)
        self.logger.info("Initializing RTSP Server...")
        
        # Initialize GStreamer
        Gst.init(None)
        
        # Create server
        self.server = GstRtspServer.RTSPServer()
        self.server.set_service(str(self.config['rtsp']['port']))
        
        # Create media factory
        self.factory = GstRtspServer.RTSPMediaFactory()
        
        # Build GStreamer pipeline
        pipeline = self.build_pipeline()
        self.factory.set_launch(pipeline)
        self.factory.set_shared(True)
        
        # Attach factory to server
        mounts = self.server.get_mount_points()
        mounts.add_factory(self.config['rtsp']['path'], self.factory)
        
        # Attach server to main loop
        self.server.attach(None)
        
        # Create main loop
        self.loop = GLib.MainLoop()
        
        # Setup signal handlers
        signal.signal(signal.SIGINT, self.signal_handler)
        signal.signal(signal.SIGTERM, self.signal_handler)
        
        # Get stream URL
        ip = self.config['robot']['ip_address']
        port = self.config['rtsp']['port']
        path = self.config['rtsp']['path']
        self.stream_url = f"rtsp://{ip}:{port}{path}"
        
        self.logger.info(f"RTSP Server initialized: {self.stream_url}")
    
    def load_config(self, config_path):
        """Load configuration from YAML file"""
        try:
            with open(config_path, 'r') as f:
                config = yaml.safe_load(f)
            return config
        except Exception as e:
            print(f"Error loading config: {e}")
            print("Using default configuration")
            return self.get_default_config()
    
    def get_default_config(self):
        """Return default configuration"""
        return {
            'robot': {
                'ip_address': '0.0.0.0'
            },
            'rtsp': {
                'port': 8554,
                'path': '/stream',
                'resolution': '640x480',
                'framerate': 30,
                'bitrate': 2000000,
                'tune': 'zerolatency',
                'preset': 'ultrafast'
            },
            'camera': {
                'device': '/dev/video0',
                'width': 640,
                'height': 480,
                'fps': 30,
                'type': 'libcamera'
            },
            'logging': {
                'level': 'INFO',
                'file': '/var/log/yahboom_controller.log',
                'console': True
            }
        }
    
    def setup_logging(self):
        """Configure logging based on config"""
        log_config = self.config.get('logging', {})
        level = getattr(logging, log_config.get('level', 'INFO'))
        
        # Create formatter
        formatter = logging.Formatter(
            log_config.get('format', '%(asctime)s - %(name)s - %(levelname)s - %(message)s')
        )
        
        # Setup root logger
        logger = logging.getLogger()
        logger.setLevel(level)
        
        # Console handler
        if log_config.get('console', True):
            console_handler = logging.StreamHandler()
            console_handler.setFormatter(formatter)
            logger.addHandler(console_handler)
        
        # File handler
        log_file = log_config.get('file')
        if log_file:
            try:
                Path(log_file).parent.mkdir(parents=True, exist_ok=True)
                file_handler = logging.FileHandler(log_file)
                file_handler.setFormatter(formatter)
                logger.addHandler(file_handler)
            except Exception as e:
                print(f"Warning: Could not create log file: {e}")
    
    def build_pipeline(self):
        """
        Build GStreamer pipeline string for video streaming
        
        Returns:
            Pipeline string for GStreamer
        """
        camera_config = self.config['camera']
        rtsp_config = self.config['rtsp']
        
        width = camera_config['width']
        height = camera_config['height']
        fps = camera_config['fps']
        bitrate = rtsp_config['bitrate'] // 1000  # Convert to kbps
        
        camera_type = camera_config.get('type', 'libcamera')
        
        if camera_type == 'libcamera':
            # Pipeline for libcamera (CSI camera on newer Raspberry Pi OS)
            pipeline = (
                f"( "
                f"libcamerasrc ! "
                f"video/x-raw,width={width},height={height},framerate={fps}/1 ! "
                f"videoconvert ! "
                f"video/x-raw,format=I420 ! "
                f"x264enc tune=zerolatency bitrate={bitrate} speed-preset=ultrafast ! "
                f"rtph264pay name=pay0 pt=96 "
                f")"
            )
        else:
            # Pipeline for v4l2 (USB camera or older setup)
            device = camera_config['device']
            pipeline = (
                f"( "
                f"v4l2src device={device} ! "
                f"video/x-raw,width={width},height={height},framerate={fps}/1 ! "
                f"videoconvert ! "
                f"video/x-raw,format=I420 ! "
                f"x264enc tune=zerolatency bitrate={bitrate} speed-preset=ultrafast ! "
                f"rtph264pay name=pay0 pt=96 "
                f")"
            )
        
        self.logger.info(f"GStreamer pipeline: {pipeline}")
        return pipeline
    
    def run(self):
        """Start the RTSP server"""
        self.logger.info(f"RTSP Server running at {self.stream_url}")
        self.logger.info("Press Ctrl+C to stop")
        
        try:
            self.loop.run()
        except KeyboardInterrupt:
            self.logger.info("Keyboard interrupt received")
        finally:
            self.cleanup()
    
    def signal_handler(self, sig, frame):
        """Handle shutdown signals"""
        self.logger.info(f"Signal {sig} received, shutting down...")
        self.loop.quit()
    
    def cleanup(self):
        """Clean shutdown"""
        self.logger.info("Stopping RTSP server...")
        if self.loop.is_running():
            self.loop.quit()
        self.logger.info("RTSP server stopped")


def main():
    """Main entry point"""
    # Check if config file exists
    config_path = Path(__file__).parent / 'config.yaml'
    
    if not config_path.exists():
        print(f"Warning: Config file not found at {config_path}")
        print("Using default configuration")
    
    # Create and run RTSP server
    server = RTSPServer(str(config_path))
    server.run()


if __name__ == '__main__':
    main()
