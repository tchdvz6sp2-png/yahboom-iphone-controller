//
//  ConnectionIndicator.swift
//  YahboomController
//
//  Visual indicator for connection state
//

import SwiftUI

struct ConnectionIndicator: View {
    
    // MARK: - Properties
    
    let state: ConnectionState
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(indicatorColor)
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 1)
                )
            
            Text(statusText)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.7))
        .cornerRadius(20)
    }
    
    // MARK: - Computed Properties
    
    private var indicatorColor: Color {
        switch state {
        case .disconnected:
            return .red
        case .connecting:
            return .yellow
        case .connected:
            return .green
        case .error:
            return .red
        }
    }
    
    private var statusText: String {
        switch state {
        case .disconnected:
            return "Disconnected"
        case .connecting:
            return "Connecting..."
        case .connected:
            return "Connected"
        case .error(let message):
            return "Error: \(message)"
        }
    }
}

// MARK: - Preview

struct ConnectionIndicator_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ConnectionIndicator(state: .disconnected)
            ConnectionIndicator(state: .connecting)
            ConnectionIndicator(state: .connected)
            ConnectionIndicator(state: .error("Network timeout"))
        }
        .padding()
        .background(Color.gray)
    }
}
