#!/usr/bin/env python3
"""
Motor Test Script for Yahboom Rider Pi CM4

This script tests the motor controller functionality by sending
various movement commands and verifying motor responses.

Usage:
    python3 test_motors.py [--config CONFIG_FILE]
"""

import sys
import time
import argparse

try:
    import yaml
except ImportError:
    print("Error: PyYAML not installed. Run: pip install PyYAML")
    sys.exit(1)

try:
    from smbus2 import SMBus
    I2C_AVAILABLE = True
except ImportError:
    print("Warning: smbus2 not installed. Running in simulation mode.")
    print("Run: pip install smbus2")
    I2C_AVAILABLE = False


class MotorTester:
    """Test harness for motor controller"""
    
    def __init__(self, config):
        self.config = config
        self.bus = None
        self.i2c_address = config['motors']['i2c_address']
        self.i2c_bus_number = config['motors']['i2c_bus']
        
        if I2C_AVAILABLE:
            try:
                self.bus = SMBus(self.i2c_bus_number)
                print(f"✓ I2C bus {self.i2c_bus_number} initialized")
            except Exception as e:
                print(f"✗ Failed to initialize I2C: {e}")
                self.bus = None
        else:
            print("Running in simulation mode (no actual motor control)")
    
    def send_motor_command(self, left_speed, right_speed):
        """Send motor command via I2C"""
        left_speed = max(-100, min(100, left_speed))
        right_speed = max(-100, min(100, right_speed))
        
        left_dir = 1 if left_speed >= 0 else 0
        right_dir = 1 if right_speed >= 0 else 0
        
        data = [
            left_dir,
            abs(int(left_speed)),
            right_dir,
            abs(int(right_speed))
        ]
        
        if self.bus is not None:
            try:
                self.bus.write_i2c_block_data(self.i2c_address, 0x00, data)
                print(f"✓ Sent: Left={left_speed:4d}, Right={right_speed:4d}")
                return True
            except Exception as e:
                print(f"✗ I2C error: {e}")
                return False
        else:
            print(f"[SIM] Left={left_speed:4d}, Right={right_speed:4d}")
            return True
    
    def test_stop(self):
        """Test 1: Stop (all motors at 0)"""
        print("\n--- Test 1: Stop ---")
        return self.send_motor_command(0, 0)
    
    def test_forward(self, speed=50):
        """Test 2: Forward movement"""
        print(f"\n--- Test 2: Forward at {speed}% ---")
        return self.send_motor_command(speed, speed)
    
    def test_backward(self, speed=50):
        """Test 3: Backward movement"""
        print(f"\n--- Test 3: Backward at {speed}% ---")
        return self.send_motor_command(-speed, -speed)
    
    def test_turn_left(self, speed=50):
        """Test 4: Turn left"""
        print(f"\n--- Test 4: Turn Left at {speed}% ---")
        return self.send_motor_command(-speed, speed)
    
    def test_turn_right(self, speed=50):
        """Test 5: Turn right"""
        print(f"\n--- Test 5: Turn Right at {speed}% ---")
        return self.send_motor_command(speed, -speed)
    
    def test_gradual_acceleration(self):
        """Test 6: Gradual acceleration"""
        print("\n--- Test 6: Gradual Acceleration ---")
        success = True
        
        for speed in range(0, 101, 10):
            if not self.send_motor_command(speed, speed):
                success = False
                break
            time.sleep(0.2)
        
        self.send_motor_command(0, 0)
        return success
    
    def test_individual_motors(self):
        """Test 7: Individual motor control"""
        print("\n--- Test 7: Individual Motors ---")
        
        print("Left motor only:")
        if not self.send_motor_command(50, 0):
            return False
        time.sleep(1)
        
        print("Right motor only:")
        if not self.send_motor_command(0, 50):
            return False
        time.sleep(1)
        
        self.send_motor_command(0, 0)
        return True
    
    def run_all_tests(self, interactive=True):
        """Run all motor tests"""
        print("=" * 60)
        print("Motor Controller Test Suite")
        print("=" * 60)
        
        if interactive:
            print("\nThis will test various motor movements.")
            print("Ensure the robot is safely positioned!")
            response = input("\nContinue? (y/n): ")
            if response.lower() != 'y':
                print("Tests cancelled.")
                return
        
        tests = [
            self.test_stop,
            lambda: self.test_forward(30),
            lambda: self.test_backward(30),
            lambda: self.test_turn_left(30),
            lambda: self.test_turn_right(30),
            self.test_gradual_acceleration,
            self.test_individual_motors,
        ]
        
        passed = 0
        failed = 0
        
        for i, test in enumerate(tests, 1):
            try:
                if interactive and i > 1:
                    input(f"\nPress Enter to run next test...")
                
                if test():
                    passed += 1
                else:
                    failed += 1
                
                time.sleep(0.5)
                self.send_motor_command(0, 0)  # Stop between tests
                time.sleep(0.5)
                
            except KeyboardInterrupt:
                print("\n\nTests interrupted by user")
                break
            except Exception as e:
                print(f"✗ Test failed with error: {e}")
                failed += 1
        
        print("\n" + "=" * 60)
        print(f"Test Results: {passed} passed, {failed} failed")
        print("=" * 60)
        
        # Final stop
        self.send_motor_command(0, 0)
    
    def close(self):
        """Close I2C bus"""
        if self.bus is not None:
            self.bus.close()
            print("\n✓ I2C bus closed")


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
    parser = argparse.ArgumentParser(description='Test Yahboom Motors')
    parser.add_argument('--config', default='config.yaml',
                       help='Path to configuration file')
    parser.add_argument('--non-interactive', action='store_true',
                       help='Run tests without user prompts')
    args = parser.parse_args()
    
    # Load configuration
    config = load_config(args.config)
    
    # Create tester
    tester = MotorTester(config)
    
    try:
        # Run tests
        tester.run_all_tests(interactive=not args.non_interactive)
    
    finally:
        # Cleanup
        tester.close()


if __name__ == '__main__':
    main()
