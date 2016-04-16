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

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        let audioSession = AVAudioSession.sharedInstance()
        let commandCenter = MPRemoteCommandCenter.sharedCommandCenter()
        let nowPlayingInfoCenter = MPNowPlayingInfoCenter.defaultCenter()
        let notificationCenter = NSNotificationCenter.defaultCenter()
        let bundle = NSBundle.mainBundle()
        
        self.player = LGAudioPlayer(dependencies: (audioSession, commandCenter, nowPlayingInfoCenter, notificationCenter))
        
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        self.window!.makeKeyAndVisible()
        self.window!.rootViewController = PlaylistViewController(dependencies: (self.player, bundle, notificationCenter))
        
        return true
    }
    
}
