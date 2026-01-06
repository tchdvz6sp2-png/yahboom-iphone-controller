//
//  AppDelegate.swift
//  YahboomController
//
//  Yahboom Rider Pi CM4 Controller Application
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, 
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Configure app-wide settings
        configureAppearance()
        
        // Initialize connection manager
        _ = ConnectionManager.shared
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, 
                    configurationForConnecting connectingSceneSession: UISceneSession, 
                    options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        
        return UISceneConfiguration(name: "Default Configuration", 
                                   sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, 
                    didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
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
