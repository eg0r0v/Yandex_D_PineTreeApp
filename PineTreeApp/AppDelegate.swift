//
//  AppDelegate.swift
//  PineTreeApp
//
//  Created by Илья Егоров on 19.11.2022.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        setupWindow()
        
        return true
    }

    private func setupWindow() {
        window = UIWindow(frame: UIScreen.main.bounds)
        
        guard let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() else { return }
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.isNavigationBarHidden = true
        window?.rootViewController = navigationController
        
        window?.makeKeyAndVisible()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        ConnectionManager.stop()
    }
}

