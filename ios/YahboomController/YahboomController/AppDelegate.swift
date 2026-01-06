//
//  AppDelegate.swift
//  YahboomController
//
//  Yahboom Rider Pi CM4 Controller Application
//  (Legacy - kept for backward compatibility)
//

import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, 
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Configure app-wide settings
        configureAppearance()
        
        return true
    }
    
    // MARK: - Private Methods
    
    private func configureAppearance() {
        // Configure global UI appearance
        if #available(iOS 15.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
