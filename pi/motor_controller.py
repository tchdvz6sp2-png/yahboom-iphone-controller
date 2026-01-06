#!/usr/bin/env python3
"""
Motor Controller for Yahboom Rider Pi CM4 Balancing Robot

This script receives UDP motor control commands and controls the robot's motors
via I2C communication. It includes safety features like command timeout and
emergency stop functionality.

Usage:
    python3 motor_controller.py [--config CONFIG_FILE]
"""

import socket
import json
import time
import logging
import signal
import sys
import argparse
from threading import Thread, Lock
from datetime import datetime, timedelta

try:
    import yaml
except ImportError:
    print("Error: PyYAML not installed. Run: pip install PyYAML")
    sys.exit(1)

try:
    from smbus2 import SMBus
except ImportError:
    print("Warning: smbus2 not installed. Motor control will be simulated.")
    print("Run: pip install smbus2")
    SMBus = None


class MotorController:
    """Handles motor control via I2C communication"""
    
    def __init__(self, config):
        self.config = config
        self.bus = None
        self.i2c_address = config['motors']['i2c_address']
        self.i2c_bus_number = config['motors']['i2c_bus']
        self.speed_limit = config['motors']['speed_limit']
        self.invert_left = config['motors']['invert_left']
        self.invert_right = config['motors']['invert_right']
        self.lock = Lock()
        
        self._initialize_i2c()
    
    def _initialize_i2c(self):
        """Initialize I2C bus connection"""
        if SMBus is None:
            logging.warning("I2C communication not available (simulation mode)")
            return
        
        try:
            self.bus = SMBus(self.i2c_bus_number)
            logging.info(f"I2C bus initialized on bus {self.i2c_bus_number}")
        except Exception as e:
            logging.error(f"Failed to initialize I2C: {e}")
            logging.warning("Running in simulation mode")
    
    def set_motor_speeds(self, left_speed, right_speed):
        """
        Set motor speeds
        
        Args:
            left_speed: Speed for left motor (-100 to 100)
            right_speed: Speed for right motor (-100 to 100)
        """
        # Apply speed limits
        left_speed = max(-self.speed_limit, min(self.speed_limit, left_speed))
        right_speed = max(-self.speed_limit, min(self.speed_limit, right_speed))
        
        # Apply inversions if configured
        if self.invert_left:
            left_speed = -left_speed
        if self.invert_right:
            right_speed = -right_speed
        
        with self.lock:
            if self.bus is not None:
                try:
                    # Convert speeds to bytes for I2C transmission
                    # Format: [left_direction, left_speed, right_direction, right_speed]
                    left_dir = 1 if left_speed >= 0 else 0
                    right_dir = 1 if right_speed >= 0 else 0
                    
                    data = [
                        left_dir,
                        abs(int(left_speed)),
                        right_dir,
                        abs(int(right_speed))
                    ]
                    
                    self.bus.write_i2c_block_data(self.i2c_address, 0x00, data)
                    logging.debug(f"Motors set: L={left_speed}, R={right_speed}")
                except Exception as e:
                    logging.error(f"I2C write error: {e}")
            else:
                logging.debug(f"[SIMULATION] Motors: L={left_speed}, R={right_speed}")
    
    def stop(self):
        """Emergency stop - set all motors to 0"""
        logging.info("Emergency stop activated")
        self.set_motor_speeds(0, 0)
    
    def close(self):
        """Close I2C connection"""
        if self.bus is not None:
            try:
                self.bus.close()
                logging.info("I2C bus closed")
            except Exception as e:
                logging.error(f"Error closing I2C bus: {e}")


class UDPMotorServer:
    """UDP server for receiving motor control commands"""
    
    def __init__(self, config, motor_controller):
        self.config = config
        self.motor_controller = motor_controller
        self.socket = None
        self.running = False
        self.last_command_time = None
        self.command_timeout = config['motors']['command_timeout']
        self.watchdog_enabled = config['safety']['watchdog_enabled']
        
    def start(self):
        """Start the UDP server"""
        port = self.config['network']['motor_udp_port']
        bind_address = self.config['network']['bind_address']
        
        try:
            self.socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            self.socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            self.socket.bind((bind_address, port))
            self.socket.settimeout(0.1)  # 100ms timeout for checking running flag
            
            logging.info(f"UDP server listening on {bind_address}:{port}")
            self.running = True
            
            # Start watchdog thread
            if self.watchdog_enabled:
                watchdog_thread = Thread(target=self._watchdog, daemon=True)
                watchdog_thread.start()
            
            self._receive_loop()
            
        except Exception as e:
            logging.error(f"Failed to start UDP server: {e}")
            raise
    
    def _receive_loop(self):
        """Main receive loop"""
        while self.running:
            try:
                data, addr = self.socket.recvfrom(
                    self.config['performance']['udp_buffer_size']
                )
                self.last_command_time = datetime.now()
                self._process_command(data, addr)
                
            except socket.timeout:
                continue
            except Exception as e:
                if self.running:
                    logging.error(f"Error in receive loop: {e}")
    
    def _process_command(self, data, addr):
        """
        Process incoming motor control command
        
        Expected JSON format:
        {
            "left": -100 to 100,
            "right": -100 to 100,
            "timestamp": unix_timestamp (optional)
        }
        """
        try:
            command = json.loads(data.decode('utf-8'))
            
            left_speed = command.get('left', 0)
            right_speed = command.get('right', 0)
            
            # Validate speeds
            if not isinstance(left_speed, (int, float)) or \
               not isinstance(right_speed, (int, float)):
                logging.warning(f"Invalid speed values from {addr}")
                return
            
            # Apply motor commands
            self.motor_controller.set_motor_speeds(left_speed, right_speed)
            
            logging.debug(f"Command from {addr}: L={left_speed}, R={right_speed}")
            
        except json.JSONDecodeError:
            logging.warning(f"Invalid JSON from {addr}: {data}")
        except Exception as e:
            logging.error(f"Error processing command: {e}")
    
    def _watchdog(self):
        """Watchdog timer - stops motors if no commands received"""
        logging.info("Watchdog timer started")
        
        while self.running:
            time.sleep(0.1)
            
            if self.last_command_time is not None:
                elapsed = (datetime.now() - self.last_command_time).total_seconds()
                
                if elapsed > self.command_timeout:
                    logging.warning("Command timeout - stopping motors")
                    self.motor_controller.stop()
                    self.last_command_time = None
    
    def stop(self):
        """Stop the UDP server"""
        logging.info("Stopping UDP server...")
        self.running = False
        
        if self.socket:
            self.socket.close()


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
    parser = argparse.ArgumentParser(description='Yahboom Motor Controller')
    parser.add_argument('--config', default='config.yaml',
                       help='Path to configuration file')
    args = parser.parse_args()
    
    # Load configuration
    config = load_config(args.config)
    
    # Setup logging
    setup_logging(config)
    
    logging.info("=" * 60)
    logging.info("Yahboom Rider Pi CM4 Motor Controller Starting")
    logging.info("=" * 60)
    
    # Initialize motor controller
    motor_controller = MotorController(config)
    
    # Initialize UDP server
    udp_server = UDPMotorServer(config, motor_controller)
    
    # Setup signal handlers
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    try:
        # Start server
        udp_server.start()
        
    except KeyboardInterrupt:
        logging.info("Keyboard interrupt received")
    
    finally:
        # Cleanup
        logging.info("Shutting down...")
        udp_server.stop()
        motor_controller.stop()
        motor_controller.close()
        logging.info("Shutdown complete")


if __name__ == '__main__':
    main()
