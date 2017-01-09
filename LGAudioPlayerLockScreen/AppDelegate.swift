//
//  AppDelegate.swift
//  LGAudioPlayerLockScreen
//
//  Created by Luka Gabric on 07/04/16.
//  Copyright © 2016 Luka Gabric. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var player: LGAudioPlayer!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        let audioSession = AVAudioSession.sharedInstance()
        let commandCenter = MPRemoteCommandCenter.shared()
        let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
        let notificationCenter = NotificationCenter.default
        let bundle = Bundle.main
        
        self.player = LGAudioPlayer(dependencies: (audioSession, commandCenter, nowPlayingInfoCenter, notificationCenter))
        
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window!.makeKeyAndVisible()
        self.window!.rootViewController = PlaylistViewController(dependencies: (self.player, bundle, notificationCenter))
        
        return true
    }
    
}
