//
//  AppDelegate.swift
//  MetallicImageDemo_iOS
//
//  Created by Xerol Wong on 3/4/20.
//  Copyright © 2020 Xerol Wong. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        let mainViewController = ViewController()
        window?.rootViewController = NavigationController(rootViewController: mainViewController)
        window?.makeKeyAndVisible()

        addWindowSizeHandlerForMacOS()
        return true
    }

    func addWindowSizeHandlerForMacOS() {
        UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.forEach { windowScene in
            windowScene.sizeRestrictions?.minimumSize = CGSize(width: 500, height: 800)
            windowScene.sizeRestrictions?.maximumSize = CGSize(width: 1000, height: 1500)
        }
    }
}
