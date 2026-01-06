#!/usr/bin/env python3
"""
Motor Controller for Yahboom Rider Pi CM4 Balancing Robot

This script listens for UDP motor control commands from the iOS app
and sends them to the robot's motor controller via serial communication
or Yahboom SDK.

Features:
- UDP command reception (20Hz update rate)
- Emergency stop on timeout (1 second)
- Serial communication fallback
- Configuration via YAML file
- Comprehensive logging
"""

import socket
import json
import time
import logging
import signal
import sys
from pathlib import Path
from datetime import datetime
import yaml

# Try to import serial (pyserial)
try:
    import serial
    SERIAL_AVAILABLE = True
except ImportError:
    SERIAL_AVAILABLE = False
    print("Warning: pyserial not installed. Serial communication disabled.")

# Try to import Yahboom SDK (if available)
# 
# Yahboom SDK Installation Instructions:
# 1. Check Yahboom's official documentation for their Python SDK
# 2. Typically available at: https://www.yahboom.net/study/CM4-Robot
# 3. Or install from their GitHub repository
# 4. Once installed, uncomment the import below and set YAHBOOM_SDK_AVAILABLE = True
# 5. Update send_sdk_command() method with actual SDK calls
#
# Example installation (adjust based on actual SDK):
#   git clone https://github.com/YahboomTechnology/CM4-Robot.git
#   cd CM4-Robot/Python_SDK
#   sudo python3 setup.py install
#
try:
    # import yahboom_sdk  # Uncomment when SDK is installed
    YAHBOOM_SDK_AVAILABLE = False  # Set to True when SDK is available
except ImportError:
    YAHBOOM_SDK_AVAILABLE = False


class MotorController:
    """Handles motor control for the Yahboom robot"""
    
    def __init__(self, config_path='config.yaml'):
        """
        Initialize the motor controller
        
        Args:
            config_path: Path to configuration YAML file
        """
        # Load configuration
        self.config = self.load_config(config_path)
        
        # Setup logging
        self.setup_logging()
        self.logger = logging.getLogger(__name__)
        self.logger.info("Initializing Motor Controller...")
        
        # Motor state
        self.current_speed = 0
        self.current_direction = 0
        self.last_command_time = time.time()
        self.running = True
        
        # Initialize serial connection
        self.serial_conn = None
        if self.config['motor']['control_mode'] == 'serial' and SERIAL_AVAILABLE:
            self.init_serial()
        
        # Initialize UDP socket
        self.sock = None
        self.init_udp()
        
        # Setup signal handlers for graceful shutdown
        signal.signal(signal.SIGINT, self.signal_handler)
        signal.signal(signal.SIGTERM, self.signal_handler)
        
        self.logger.info("Motor Controller initialized successfully")
    
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
            'motor': {
                'udp_port': 5000,
                'serial_port': '/dev/ttyUSB0',
                'serial_baudrate': 115200,
                'max_speed': 100,
                'max_turn_speed': 80,
                'timeout': 1.0,
                'control_mode': 'serial'
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
        
        # File handler (create directory if needed)
        log_file = log_config.get('file')
        if log_file:
            try:
                Path(log_file).parent.mkdir(parents=True, exist_ok=True)
                file_handler = logging.FileHandler(log_file)
                file_handler.setFormatter(formatter)
                logger.addHandler(file_handler)
            except Exception as e:
                print(f"Warning: Could not create log file: {e}")
    
    def init_serial(self):
        """Initialize serial connection to motor controller"""
        try:
            port = self.config['motor']['serial_port']
            baudrate = self.config['motor']['serial_baudrate']
            
            self.logger.info(f"Opening serial port {port} at {baudrate} baud")
            self.serial_conn = serial.Serial(
                port=port,
                baudrate=baudrate,
                timeout=1.0
            )
            self.logger.info("Serial connection established")
        except Exception as e:
            self.logger.error(f"Failed to open serial port: {e}")
            self.serial_conn = None
    
    def init_udp(self):
        """Initialize UDP socket for receiving commands"""
        try:
            port = self.config['motor']['udp_port']
            self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            self.sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            self.sock.bind(('0.0.0.0', port))
            self.sock.settimeout(0.1)  # 100ms timeout for checking stop condition
            
            self.logger.info(f"UDP socket listening on port {port}")
        except Exception as e:
            self.logger.error(f"Failed to create UDP socket: {e}")
            raise
    
    def parse_command(self, data):
        """
        Parse motor command from JSON data
        
        Args:
            data: JSON string with command data
            
        Returns:
            Dictionary with parsed command or None if invalid
        """
        try:
            command = json.loads(data)
            
            # Validate required fields
            if 'command' not in command:
                self.logger.warning("Command missing 'command' field")
                return None
            
            # Add timestamp if not present
            if 'timestamp' not in command:
                command['timestamp'] = time.time()
            
            return command
            
        except json.JSONDecodeError as e:
            self.logger.warning(f"Invalid JSON received: {e}")
            return None
    
    def execute_command(self, command):
        """
        Execute a motor command
        
        Args:
            command: Dictionary containing command data
        """
        cmd_type = command.get('command')
        
        if cmd_type == 'move':
            speed = command.get('speed', 0)
            direction = command.get('direction', 0)
            
            # Clamp values to safe ranges
            speed = max(-100, min(100, speed))
            direction = max(-100, min(100, direction))
            
            self.set_motor_speed(speed, direction)
            
        elif cmd_type == 'stop':
            self.stop_motors()
            
        else:
            self.logger.warning(f"Unknown command type: {cmd_type}")
    
    def set_motor_speed(self, speed, direction):
        """
        Set motor speed and direction
        
        Args:
            speed: Forward/backward speed (-100 to 100)
            direction: Left/right turning (-100 to 100)
        """
        self.current_speed = speed
        self.current_direction = direction
        self.last_command_time = time.time()
        
        self.logger.debug(f"Motor command: speed={speed}, direction={direction}")
        
        # Send to hardware
        if self.config['motor']['control_mode'] == 'sdk' and YAHBOOM_SDK_AVAILABLE:
            self.send_sdk_command(speed, direction)
        elif self.config['motor']['control_mode'] == 'serial' and self.serial_conn:
            self.send_serial_command(speed, direction)
        else:
            self.logger.debug("Motor command (simulation mode - no hardware connected)")
    
    def send_serial_command(self, speed, direction):
        """
        Send motor command via serial port
        
        This is a generic implementation. Adjust based on your motor controller protocol.
        
        Args:
            speed: Forward/backward speed (-100 to 100)
            direction: Left/right turning (-100 to 100)
        """
        try:
            # Convert to left/right motor speeds
            # This is a simplified differential drive calculation
            left_speed = speed + direction
            right_speed = speed - direction
            
            # Clamp to motor limits
            max_speed = self.config['motor']['max_speed']
            left_speed = max(-max_speed, min(max_speed, left_speed))
            right_speed = max(-max_speed, min(max_speed, right_speed))
            
            # Format command (adjust based on actual protocol)
            # Example format: "M,left_speed,right_speed\n"
            command = f"M,{int(left_speed)},{int(right_speed)}\n"
            
            # Send via serial
            self.serial_conn.write(command.encode())
            
            self.logger.debug(f"Sent serial command: {command.strip()}")
            
        except Exception as e:
            self.logger.error(f"Error sending serial command: {e}")
    
    def send_sdk_command(self, speed, direction):
        """
        Send motor command via Yahboom SDK
        
        Args:
            speed: Forward/backward speed (-100 to 100)
            direction: Left/right turning (-100 to 100)
        """
        # Placeholder for Yahboom SDK implementation
        # Replace with actual SDK calls when available
        try:
            # Example (adjust based on actual SDK):
            # yahboom_sdk.set_motor_speed(speed, direction)
            pass
        except Exception as e:
            self.logger.error(f"Error sending SDK command: {e}")
    
    def stop_motors(self):
        """Emergency stop - halt all motors"""
        self.logger.info("EMERGENCY STOP - Halting all motors")
        self.current_speed = 0
        self.current_direction = 0
        self.set_motor_speed(0, 0)
    
    def check_timeout(self):
        """Check if motor command timeout has occurred"""
        timeout = self.config['motor']['timeout']
        elapsed = time.time() - self.last_command_time
        
        if elapsed > timeout and (self.current_speed != 0 or self.current_direction != 0):
            self.logger.warning(f"Command timeout ({elapsed:.1f}s) - Emergency stop")
            self.stop_motors()
    
    def run(self):
        """Main control loop"""
        self.logger.info("Motor controller started. Press Ctrl+C to stop.")
        
        try:
            while self.running:
                try:
                    # Receive UDP packet
                    data, addr = self.sock.recvfrom(1024)
                    
                    # Parse command
                    command = self.parse_command(data.decode('utf-8'))
                    
                    if command:
                        self.logger.debug(f"Received command from {addr}: {command}")
                        self.execute_command(command)
                    
                except socket.timeout:
                    # No data received - check for timeout
                    pass
                
                # Check for command timeout
                self.check_timeout()
                
        except KeyboardInterrupt:
            self.logger.info("Keyboard interrupt received")
        finally:
            self.cleanup()
    
    def signal_handler(self, sig, frame):
        """Handle shutdown signals"""
        self.logger.info(f"Signal {sig} received, shutting down...")
        self.running = False
    
    def cleanup(self):
        """Clean shutdown"""
        self.logger.info("Cleaning up...")
        
        # Stop motors
        self.stop_motors()
        
        # Close serial connection
        if self.serial_conn:
            self.logger.info("Closing serial connection")
            self.serial_conn.close()
        
        # Close UDP socket
        if self.sock:
            self.logger.info("Closing UDP socket")
            self.sock.close()
        
        self.logger.info("Motor controller stopped")


def main():
    """Main entry point"""
    # Check if config file exists
    config_path = Path(__file__).parent / 'config.yaml'
    
    if not config_path.exists():
        print(f"Warning: Config file not found at {config_path}")
        print("Using default configuration")
    
    # Create and run motor controller
    controller = MotorController(str(config_path))
    controller.run()


if __name__ == '__main__':
    main()
