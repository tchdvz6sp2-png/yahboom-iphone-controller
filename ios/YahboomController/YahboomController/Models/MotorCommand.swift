//
//  MotorCommand.swift
//  YahboomController
//
//  Motor command model for UDP transmission
//

import Foundation

/// Motor command sent to the robot via UDP
struct MotorCommand: Codable {
    /// Command type
    let command: String
    
    /// Speed value (-100 to 100, forward/backward)
    let speed: Int
    
    /// Direction value (-100 to 100, left/right)
    let direction: Int
    
    /// Timestamp when command was created
    let timestamp: TimeInterval
    
    /// Create a move command
    static func move(speed: Int, direction: Int) -> MotorCommand {
        return MotorCommand(
            command: "move",
            speed: clamp(speed, min: -100, max: 100),
            direction: clamp(direction, min: -100, max: 100),
            timestamp: Date().timeIntervalSince1970
        )
    }
    
    /// Create a stop command
    static func stop() -> MotorCommand {
        return MotorCommand(
            command: "stop",
            speed: 0,
            direction: 0,
            timestamp: Date().timeIntervalSince1970
        )
    }
    
    /// Convert to JSON data for UDP transmission
    func toData() -> Data? {
        return try? JSONEncoder().encode(self)
    }
    
    /// Clamp value to range
    private static func clamp(_ value: Int, min: Int, max: Int) -> Int {
        return Swift.max(min, Swift.min(max, value))
    }
}
