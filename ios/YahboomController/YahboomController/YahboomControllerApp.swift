//
//  YahboomControllerApp.swift
//  YahboomController
//
//  SwiftUI App entry point
//

import SwiftUI

@main
struct YahboomControllerApp: App {
    
    var body: some Scene {
        WindowGroup {
            MainControlView()
                .preferredColorScheme(.dark)
        }
    }
}
