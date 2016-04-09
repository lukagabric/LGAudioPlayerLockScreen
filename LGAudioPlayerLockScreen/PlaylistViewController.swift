//
//  RootViewController.swift
//  LGAudioPlayerLockScreen
//
//  Created by Luka Gabric on 08/04/16.
//  Copyright © 2016 Luka Gabric. All rights reserved.
//

import UIKit

class PlaylistViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    //MARK: - Vars
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var playerButton: UIButton!
    @IBOutlet weak var playerButtonHeight: NSLayoutConstraint!
    
    var player: LGAudioPlayer {
        return LGAudioPlayer.sharedPlayer
    }

    //MARK: - Init
    
    init() {
        super.init(nibName: "PlaylistView", bundle: NSBundle.mainBundle())
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(onTrackAndPlaybackStateChange), name: LGAudioPlayerOnTrackChangedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(onTrackAndPlaybackStateChange), name: LGAudioPlayerOnPlaybackStateChangedNotification, object: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    //MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.tableFooterView = UIView()
        self.tableView.rowHeight = 60
        
        self.updatePlayerButton(animated: false)
    }
    
    //MARK: - Notifications
    
    func onTrackAndPlaybackStateChange() {
        self.updatePlayerButton(animated: true)
        self.tableView.reloadData()
    }
    
    //MARK: - Updates
    
    func updatePlayerButton(animated animated: Bool) {
        let updateView = {
            if self.player.currentPlaybackItem == nil {
                self.playerButtonHeight.constant = 0
                self.playerButton.alpha = 0
            }
            else {
                self.playerButtonHeight.constant = 50
                self.playerButton.alpha = 1
            }
        }
        
        if animated {
            UIView.animateWithDuration(0.5, delay: 0, options: .BeginFromCurrentState, animations: {
                updateView()
                self.view.layoutIfNeeded()
                }, completion: nil)
        } else {
            updateView()
        }
    }
    
    //MARK: - Actions
    
    @IBAction func showPlayerAction(sender: AnyObject) {
        self.presentViewController(LGPlayerViewController(), animated: true, completion: nil)
    }
    
    //MARK: - UITableViewDelegate, UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.playlist.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let playbackItem = self.playlist[indexPath.row]
        let cell = PlaybackItemCell(playbackItem: playbackItem)
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.player.playItems(self.playlist, firstItem: self.playlist[indexPath.row])
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    //MARK: - Playlist Items
    
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
