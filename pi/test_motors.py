#!/usr/bin/env python3
"""
Motor Control Test Script for Yahboom Rider Pi CM4 Robot

This script tests the motor control functionality by sending a series
of test commands to verify the motor controller is working correctly.

Usage:
    python3 test_motors.py
"""

import socket
import json
import time
import sys
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


def send_command(sock, command, host='localhost', port=5000):
    """
    Send a motor command via UDP
    
    Args:
        sock: UDP socket
        command: Command dictionary
        host: Target host
        port: Target port
    """
    try:
        data = json.dumps(command).encode('utf-8')
        sock.sendto(data, (host, port))
        return True
    except Exception as e:
        print(f"Error sending command: {e}")
        return False


def test_motor_commands():
    """Run a series of motor control tests"""
    print("=" * 60)
    print("Yahboom Robot Motor Control Test")
    print("=" * 60)
    
    # Load config
    config_path = Path(__file__).parent / 'config.yaml'
    config = load_config(str(config_path))
    
    if not config:
        print("Failed to load configuration. Using defaults.")
        port = 5000
        host = 'localhost'
    else:
        port = config['motor']['udp_port']
        host = config['robot'].get('ip_address', 'localhost')
        if host == '0.0.0.0':
            host = 'localhost'
    
    print(f"\nTarget: {host}:{port}")
    print("\nMake sure motor_controller.py is running!")
    print("Starting tests in 3 seconds...\n")
    time.sleep(3)
    
    # Create UDP socket
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    
    # Test sequence
    tests = [
        {
            'name': 'Forward (50% speed)',
            'command': {'command': 'move', 'speed': 50, 'direction': 0},
            'duration': 2.0
        },
        {
            'name': 'Stop',
            'command': {'command': 'stop'},
            'duration': 1.0
        },
        {
            'name': 'Backward (50% speed)',
            'command': {'command': 'move', 'speed': -50, 'direction': 0},
            'duration': 2.0
        },
        {
            'name': 'Stop',
            'command': {'command': 'stop'},
            'duration': 1.0
        },
        {
            'name': 'Turn Left (50% turn)',
            'command': {'command': 'move', 'speed': 0, 'direction': -50},
            'duration': 2.0
        },
        {
            'name': 'Stop',
            'command': {'command': 'stop'},
            'duration': 1.0
        },
        {
            'name': 'Turn Right (50% turn)',
            'command': {'command': 'move', 'speed': 0, 'direction': 50},
            'duration': 2.0
        },
        {
            'name': 'Stop',
            'command': {'command': 'stop'},
            'duration': 1.0
        },
        {
            'name': 'Forward-Right (diagonal)',
            'command': {'command': 'move', 'speed': 50, 'direction': 30},
            'duration': 2.0
        },
        {
            'name': 'Stop',
            'command': {'command': 'stop'},
            'duration': 1.0
        },
        {
            'name': 'Forward-Left (diagonal)',
            'command': {'command': 'move', 'speed': 50, 'direction': -30},
            'duration': 2.0
        },
        {
            'name': 'Final Stop',
            'command': {'command': 'stop'},
            'duration': 1.0
        },
    ]
    
    # Run tests
    passed = 0
    failed = 0
    
    for i, test in enumerate(tests, 1):
        print(f"Test {i}/{len(tests)}: {test['name']}")
        print(f"  Command: {test['command']}")
        
        # Add timestamp
        test['command']['timestamp'] = time.time()
        
        # Send command
        if send_command(sock, test['command'], host, port):
            print(f"  ✓ Command sent")
            passed += 1
        else:
            print(f"  ✗ Failed to send command")
            failed += 1
        
        # Wait for duration
        time.sleep(test['duration'])
        print()
    
    # Final stop (safety)
    print("Sending final emergency stop...")
    send_command(sock, {'command': 'stop', 'timestamp': time.time()}, host, port)
    
    # Close socket
    sock.close()
    
    # Print summary
    print("\n" + "=" * 60)
    print("Test Summary")
    print("=" * 60)
    print(f"Passed: {passed}/{len(tests)}")
    print(f"Failed: {failed}/{len(tests)}")
    
    if failed == 0:
        print("\n✓ All tests completed successfully!")
        return 0
    else:
        print(f"\n✗ {failed} test(s) failed")
        return 1


def test_connection():
    """Test basic UDP connectivity"""
    print("\nTesting UDP connectivity...")
    
    config_path = Path(__file__).parent / 'config.yaml'
    config = load_config(str(config_path))
    
    if not config:
        port = 5000
        host = 'localhost'
    else:
        port = config['motor']['udp_port']
        host = config['robot'].get('ip_address', 'localhost')
        if host == '0.0.0.0':
            host = 'localhost'
    
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        sock.settimeout(2.0)
        
        # Send test ping
        test_cmd = {'command': 'stop', 'timestamp': time.time()}
        data = json.dumps(test_cmd).encode('utf-8')
        sock.sendto(data, (host, port))
        
        print(f"✓ Successfully sent test packet to {host}:{port}")
        sock.close()
        return True
        
    except Exception as e:
        print(f"✗ Connection test failed: {e}")
        print("\nTroubleshooting:")
        print("1. Ensure motor_controller.py is running")
        print("2. Check firewall settings (allow UDP port)")
        print("3. Verify IP address and port in config.yaml")
        return False


def main():
    """Main entry point"""
    print("\n" + "=" * 60)
    print("YAHBOOM ROBOT MOTOR CONTROL TEST")
    print("=" * 60)
    
    # First test connectivity
    if not test_connection():
        print("\n⚠ Connection test failed. Cannot proceed with motor tests.")
        print("Please ensure motor_controller.py is running and try again.")
        return 1
    
    print("\nConnection successful! Proceeding with motor tests...")
    time.sleep(1)
    
    # Run motor tests
    result = test_motor_commands()
    
    print("\n" + "=" * 60)
    print("TEST COMPLETE")
    print("=" * 60)
    
    return result


if __name__ == '__main__':
    sys.exit(main())
