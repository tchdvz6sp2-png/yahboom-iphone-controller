//
//  JoystickView.swift
//  YahboomController
//
//  Virtual joystick for manual robot control
//

import SwiftUI

struct JoystickView: View {
    
    // MARK: - Properties
    
    @ObservedObject var controlViewModel: ControlViewModel
    
    @State private var knobPosition: CGPoint = .zero
    @GestureState private var dragState: CGPoint = .zero
    
    private let joystickSize: CGFloat = 150
    private let knobSize: CGFloat = 60
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Joystick background
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: joystickSize, height: joystickSize)
            
            // Center indicator
            Circle()
                .fill(Color.white.opacity(0.5))
                .frame(width: 10, height: 10)
            
            // Directional guides
            ForEach(0..<4) { index in
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 2, height: joystickSize / 2)
                    .offset(y: -joystickSize / 4)
                    .rotationEffect(.degrees(Double(index) * 90))
            }
            
            // Knob
            Circle()
                .fill(Color.blue)
                .frame(width: knobSize, height: knobSize)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
                .overlay(
                    Image(systemName: "arrow.up")
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(calculateAngle()))
                )
                .offset(x: knobPosition.x, y: knobPosition.y)
                .gesture(
                    DragGesture()
                        .updating($dragState) { value, state, _ in
                            state = value.translation
                        }
                        .onChanged { value in
                            updateKnobPosition(translation: value.translation)
                        }
                        .onEnded { _ in
                            resetKnob()
                        }
                )
        }
        .frame(width: joystickSize, height: joystickSize)
        .onChange(of: dragState) { _ in
            // dragState updates during gesture
        }
    }
    
    // MARK: - Joystick Logic
    
    private func updateKnobPosition(translation: CGSize) {
        // Calculate new position
        var newX = translation.width
        var newY = translation.height
        
        // Calculate distance from center
        let distance = sqrt(newX * newX + newY * newY)
        
        // Limit to joystick bounds
        let maxDistance = (joystickSize - knobSize) / 2
        if distance > maxDistance {
            let scale = maxDistance / distance
            newX *= scale
            newY *= scale
        }
        
        knobPosition = CGPoint(x: newX, y: newY)
        
        // Convert to motor commands
        updateMotorCommands()
    }
    
    private func resetKnob() {
        withAnimation(.spring()) {
            knobPosition = .zero
        }
        
        // Stop motors
        controlViewModel.updateControl(speed: 0, direction: 0)
    }
    
    private func updateMotorCommands() {
        // Convert joystick position to speed and direction
        let maxDistance = (joystickSize - knobSize) / 2
        
        // Y axis = speed (inverted: up is negative Y, but positive speed)
        let speedNormalized = -knobPosition.y / maxDistance
        let speed = Int(speedNormalized * 100)
        
        // X axis = direction
        let directionNormalized = knobPosition.x / maxDistance
        let direction = Int(directionNormalized * 100)
        
        controlViewModel.updateControl(speed: speed, direction: direction)
    }
    
    private func calculateAngle() -> Double {
        guard knobPosition != .zero else { return 0 }
        
        let angle = atan2(knobPosition.x, -knobPosition.y) * 180 / .pi
        return angle
    }
}

// MARK: - Preview

struct JoystickView_Previews: PreviewProvider {
    static var previews: some View {
        let settings = RobotSettings()
        let connectionVM = ConnectionViewModel(settings: settings)
        let controlVM = ControlViewModel(settings: settings, connectionViewModel: connectionVM)
        
        ZStack {
            Color.black
            JoystickView(controlViewModel: controlVM)
        }
    }
}
