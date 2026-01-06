//
//  YahboomControllerApp.swift
//  YahboomController
//
//  Main app entry point
//

import SwiftUI

@main
struct YahboomControllerApp: App {
    
    // MARK: - State Objects
    
    @StateObject private var settings = RobotSettings()
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(settings)
        }
    }
}
