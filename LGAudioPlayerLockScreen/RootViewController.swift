//
//  RootViewController.swift
//  LGAudioPlayerLockScreen
//
//  Created by Luka Gabric on 08/04/16.
//  Copyright © 2016 Luka Gabric. All rights reserved.
//

import UIKit

class RootViewController: UIViewController {
    
    //MARK: - Vars
    
    var player: LGAudioPlayer {
        return LGAudioPlayer.sharedPlayer
    }

    //MARK: - Init
    
    init() {
        super.init(nibName: "RootView", bundle: NSBundle.mainBundle())
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    //MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    //MARK: - Actions
    
    @IBAction func startPlaybackAction(sender: AnyObject) {
        self.player.playItems(self.playlist)
    }
    
    @IBAction func showPlayerAction(sender: AnyObject) {
        if self.player.currentPlaybackItem != nil {
            self.presentViewController(LGPlayerViewController(), animated: true, completion: nil)
        }
        else {
            UIAlertView(title: nil, message: "Tracks need to be playing", delegate: nil, cancelButtonTitle: "Close").show()
        }
    }
    
    //MARK: - Convenience
    
    lazy var playlist: [LGPlaybackItem] = {
        let playbackItem1 = LGPlaybackItem(fileName: "Best Coast - The Only Place (The Only Place)",
                                           type: "mp3",
                                           trackName: "The Only Place",
                                           albumName: "The Only Place",
                                           artistName: "Best Coast",
                                           albumImage: UIImage(named: "Best Coast - The Only Place (The Only Place)")!)
        
        let playbackItem2 = LGPlaybackItem(fileName: "Future Islands - Before the Bridge (On the Water)",
                                           type: "mp3",
                                           trackName: "Before the Bridge",
                                           albumName: "On the Water",
                                           artistName: "Future Islands",
                                           albumImage: UIImage(named: "Future Islands - Before the Bridge (On the Water).jpg")!)
        
        let playbackItem3 = LGPlaybackItem(fileName: "Motorama - Alps (Alps)",
                                           type: "mp3",
                                           trackName: "Alps",
                                           albumName: "Alps",
                                           artistName: "Motorama",
                                           albumImage: UIImage(named: "Motorama - Alps (Alps)")!)
        
        let playbackItem4 = LGPlaybackItem(fileName: "Nils Frahm - You (Screws Reworked)",
                                           type: "mp3",
                                           trackName: "You",
                                           albumName: "Screws Reworked",
                                           artistName: "Nils Frahm",
                                           albumImage: UIImage(named: "Nils Frahm - You (Screws Reworked)")!)
        
        let playbackItem5 = LGPlaybackItem(fileName: "The Soul's Release - Catching Fireflies (Where the Trees Are Painted White)",
                                           type: "mp3",
                                           trackName: "Catching Fireflies",
                                           albumName: "Where the Trees Are Painted White",
                                           artistName: "The Soul's Release",
                                           albumImage: UIImage(named: "The Soul's Release - Catching Fireflies (Where the Trees Are Painted White).jpg")!)
        
        let playbackItems = [playbackItem1, playbackItem2, playbackItem3, playbackItem4, playbackItem5]
        
        return playbackItems
    }()

    //MARK: -
    
}
