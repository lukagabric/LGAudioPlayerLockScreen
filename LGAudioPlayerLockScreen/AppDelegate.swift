//
//  AppDelegate.swift
//  LGAudioPlayerLockScreen
//
//  Created by Luka Gabric on 07/04/16.
//  Copyright © 2016 Luka Gabric. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        self.window!.makeKeyAndVisible()
        self.window!.rootViewController = RootViewController()
        return true
    }
    
}
