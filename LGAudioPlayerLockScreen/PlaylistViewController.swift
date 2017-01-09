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
    
    //MARK: - Dependencies
    
    let player: LGAudioPlayer
    let notificationCenter: NotificationCenter
    let bundle: Bundle

    //MARK: - Init
    
    typealias PlaylistViewControllerDependencies = (player: LGAudioPlayer, bundle: Bundle, notificationCenter: NotificationCenter)

    init(dependencies: PlaylistViewControllerDependencies) {
        self.player = dependencies.player
        self.notificationCenter = dependencies.notificationCenter
        self.bundle = dependencies.bundle
        
        super.init(nibName: nil, bundle: nil)
        
        self.configureNotifications()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    deinit {
        self.notificationCenter.removeObserver(self)
    }

    //MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.tableFooterView = UIView()
        self.tableView.rowHeight = 60
        
        self.updatePlayerButton(animated: false)
    }
    
    //MARK: - Notifications
    
    func configureNotifications() {
        self.notificationCenter.addObserver(self, selector: #selector(onTrackAndPlaybackStateChange), name: NSNotification.Name(rawValue: LGAudioPlayerOnTrackChangedNotification), object: nil)
        self.notificationCenter.addObserver(self, selector: #selector(onTrackAndPlaybackStateChange), name: NSNotification.Name(rawValue: LGAudioPlayerOnPlaybackStateChangedNotification), object: nil)
    }
    
    func onTrackAndPlaybackStateChange() {
        self.updatePlayerButton(animated: true)
        self.tableView.reloadData()
    }
    
    //MARK: - Updates
    
    func updatePlayerButton(animated: Bool) {
        let updateView = {
            if self.player.currentPlaybackItem == nil {
                self.playerButtonHeight.constant = 0
                self.playerButton.alpha = 0
            }
            else {
                self.playerButtonHeight.constant = 50
                self.playerButton.alpha = 1
            }
            self.view.layoutIfNeeded()
        }
        
        if animated {
            UIView.animate(withDuration: 0.5, delay: 0, options: .beginFromCurrentState, animations: updateView, completion: nil)
        }
        else {
            updateView()
        }
    }
    
    //MARK: - Actions
    
    @IBAction func showPlayerAction(_ sender: AnyObject) {
        let playerViewController = LGPlayerViewController(dependencies: (self.player, self.notificationCenter))
        self.present(playerViewController, animated: true, completion: nil)
    }
    
    //MARK: - UITableViewDelegate, UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.playlist.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let playbackItem = self.playlist[indexPath.row]
        let cell = PlaybackItemCell(player: self.player, playbackItem: playbackItem)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.player.playItems(self.playlist, firstItem: self.playlist[indexPath.row])
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    //MARK: - Playlist Items
    
    lazy var playlist: [LGPlaybackItem] = {
        let playbackItem1 = LGPlaybackItem(fileURL: URL(fileURLWithPath: self.bundle.path(forResource: "Best Coast - The Only Place (The Only Place)", ofType: "mp3")!),
                                           trackName: "The Only Place",
                                           albumName: "The Only Place",
                                           artistName: "Best Coast",
                                           albumImageName: "Best Coast - The Only Place (The Only Place)")
        
        let playbackItem2 = LGPlaybackItem(fileURL: URL(fileURLWithPath: self.bundle.path(forResource: "Future Islands - Before the Bridge (On the Water)", ofType: "mp3")!),
                                           trackName: "Before the Bridge",
                                           albumName: "On the Water",
                                           artistName: "Future Islands",
                                           albumImageName: "Future Islands - Before the Bridge (On the Water).jpg")
        
        let playbackItem3 = LGPlaybackItem(fileURL: URL(fileURLWithPath: self.bundle.path(forResource: "Motorama - Alps (Alps)", ofType: "mp3")!),
                                           trackName: "Alps",
                                           albumName: "Alps",
                                           artistName: "Motorama",
                                           albumImageName: "Motorama - Alps (Alps)")
        
        let playbackItem4 = LGPlaybackItem(fileURL: URL(fileURLWithPath: self.bundle.path(forResource: "Nils Frahm - You (Screws Reworked)", ofType: "mp3")!),
                                           trackName: "You",
                                           albumName: "Screws Reworked",
                                           artistName: "Nils Frahm",
                                           albumImageName: "Nils Frahm - You (Screws Reworked)")

        let playbackItem5 = LGPlaybackItem(fileURL: URL(fileURLWithPath: self.bundle.path(forResource: "The Soul's Release - Catching Fireflies (Where the Trees Are Painted White)", ofType: "mp3")!),
                                           trackName: "Catching Fireflies",
                                           albumName: "Where the Trees Are Painted White",
                                           artistName: "The Soul's Release",
                                           albumImageName: "The Soul's Release - Catching Fireflies (Where the Trees Are Painted White).jpg")
        
        let playbackItems = [playbackItem1, playbackItem2, playbackItem3, playbackItem4, playbackItem5]
        
        return playbackItems
    }()

    //MARK: -
    
}
