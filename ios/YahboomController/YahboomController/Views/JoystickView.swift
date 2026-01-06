//
//  JoystickView.swift
//  YahboomController
//
//  Custom joystick control view for motor control
//

import UIKit

protocol JoystickViewDelegate: AnyObject {
    func joystickDidMove(x: Double, y: Double)
    func joystickDidRelease()
}

class JoystickView: UIView {
    
    // MARK: - Properties
    weak var delegate: JoystickViewDelegate?
    
    private let baseLayer = CAShapeLayer()
    private let stickLayer = CAShapeLayer()
    
    private var currentPosition: CGPoint = .zero
    private let maxDistance: CGFloat = 60
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - Setup
    
    private func setupView() {
        backgroundColor = .clear
        
        // Base circle
        baseLayer.fillColor = UIColor.white.withAlphaComponent(0.3).cgColor
        baseLayer.strokeColor = UIColor.white.cgColor
        baseLayer.lineWidth = 2
        layer.addSublayer(baseLayer)
        
        // Stick circle
        stickLayer.fillColor = UIColor.white.withAlphaComponent(0.7).cgColor
        stickLayer.strokeColor = UIColor.white.cgColor
        stickLayer.lineWidth = 2
        layer.addSublayer(stickLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let baseRadius = min(bounds.width, bounds.height) / 2 - 10
        let stickRadius: CGFloat = 30
        
        // Base circle
        let basePath = UIBezierPath(arcCenter: center, 
                                    radius: baseRadius, 
                                    startAngle: 0, 
                                    endAngle: .pi * 2, 
                                    clockwise: true)
        baseLayer.path = basePath.cgPath
        
        // Stick circle (initially at center)
        updateStickPosition(center)
    }
    
    private func updateStickPosition(_ position: CGPoint) {
        let stickRadius: CGFloat = 30
        let stickPath = UIBezierPath(arcCenter: position, 
                                     radius: stickRadius, 
                                     startAngle: 0, 
                                     endAngle: .pi * 2, 
                                     clockwise: true)
        stickLayer.path = stickPath.cgPath
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouch(touches)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouch(touches)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        resetPosition()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        resetPosition()
    }
    
    private func handleTouch(_ touches: Set<UITouch>) {
        guard let touch = touches.first else { return }
        
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let touchPoint = touch.location(in: self)
        
        // Calculate offset from center
        var offset = CGPoint(x: touchPoint.x - center.x, 
                           y: touchPoint.y - center.y)
        
        // Limit to max distance
        let distance = sqrt(offset.x * offset.x + offset.y * offset.y)
        if distance > maxDistance {
            let scale = maxDistance / distance
            offset.x *= scale
            offset.y *= scale
        }
        
        // Update position
        let newPosition = CGPoint(x: center.x + offset.x, 
                                 y: center.y + offset.y)
        updateStickPosition(newPosition)
        
        // Normalize to -1...1 range
        let normalizedX = Double(offset.x / maxDistance)
        let normalizedY = Double(-offset.y / maxDistance)  // Invert Y for forward/backward
        
        delegate?.joystickDidMove(x: normalizedX, y: normalizedY)
    }
    
    private func resetPosition() {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        updateStickPosition(center)
        delegate?.joystickDidRelease()
    }
}
