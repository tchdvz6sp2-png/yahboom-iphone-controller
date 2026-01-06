//
//  JoystickSwiftUIView.swift
//  YahboomController
//
//  SwiftUI-based joystick control view
//

import SwiftUI

struct JoystickSwiftUIView: View {
    
    // Callback for joystick movement
    let onMove: (Double, Double) -> Void
    let onRelease: () -> Void
    
    // State for tracking stick position
    @State private var stickOffset: CGSize = .zero
    
    // Constants
    private let baseSize: CGFloat = 150
    private let stickSize: CGFloat = 60
    private let maxDistance: CGFloat = 60
    
    var body: some View {
        ZStack {
            // Base circle
            Circle()
                .fill(Color.white.opacity(0.3))
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
                .frame(width: baseSize, height: baseSize)
            
            // Stick circle
            Circle()
                .fill(Color.white.opacity(0.7))
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
                .frame(width: stickSize, height: stickSize)
                .offset(stickOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            handleDrag(value.translation)
                        }
                        .onEnded { _ in
                            resetStick()
                        }
                )
        }
        .frame(width: baseSize, height: baseSize)
    }
    
    // MARK: - Private Methods
    
    private func handleDrag(_ translation: CGSize) {
        // Calculate distance from center
        let distance = sqrt(translation.width * translation.width + translation.height * translation.height)
        
        // Limit to max distance
        var offset = translation
        if distance > maxDistance {
            let scale = maxDistance / distance
            offset = CGSize(width: translation.width * scale, height: translation.height * scale)
        } else {
            offset = translation
        }
        
        stickOffset = offset
        
        // Normalize to -1...1 range
        let normalizedX = Double(offset.width / maxDistance)
        let normalizedY = Double(-offset.height / maxDistance) // Invert Y for forward/backward
        
        onMove(normalizedX, normalizedY)
    }
    
    private func resetStick() {
        withAnimation(.spring(response: 0.3)) {
            stickOffset = .zero
        }
        onRelease()
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        JoystickSwiftUIView(
            onMove: { x, y in
                print("Joystick: x=\(x), y=\(y)")
            },
            onRelease: {
                print("Joystick released")
            }
        )
    }
}
