//
//  ViewController.swift
//  LGLockScreen
//
//  Created by Luka Gabric on 07/04/16.
//  Copyright © 2016 Luka Gabric. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    //MARK: - Vars
    
    var timer: NSTimer!

    @IBOutlet weak var artworkImageView: UIImageView!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var previousButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var elapsedTimeLabel: UILabel!
    @IBOutlet weak var remainingTimeLabel: UILabel!
    
    //MARK: - Init

    init() {
        super.init(nibName: "View", bundle: NSBundle.mainBundle())
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    //MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.player.onTrackChanged = { [weak self] in
            guard let sself = self else { return }
            
            sself.trackChanged()
        }
        
        self.player.onPlaybackStateChanged = { [weak self] in
            guard let sself = self else { return }
            
            sself.playbackStateChanged()
        }

        self.player.playItems(self.playlist)
        
        self.timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(timerFired), userInfo: nil, repeats: true)
    }
    
    //MARK: - Actions
    
    func trackChanged() {
        self.updateArtworkImageView()
        self.updateSlider()
        self.updateInfoLabels()
        self.updateTimeLabels()
        self.updateControls()
    }
    
    func playbackStateChanged() {
        self.updateControls()        
    }
    
    @IBAction func playPauseButtonAction(sender: AnyObject) {
        self.player.togglePlayPause()
    }
    
    @IBAction func previousButtonAction(sender: AnyObject) {
        self.player.previousTrack()
    }
    
    @IBAction func nextButtonAction(sender: AnyObject) {
        self.player.nextTrack()
    }
    
    func timerFired() {
        if !self.slider.tracking {
            self.slider.value = Float(self.player.currentTime ?? 0)
        }
        
        self.updateTimeLabels()
    }
    
    @IBAction func sliderValueChanged(sender: AnyObject) {
        self.player.seekTo(Double(self.slider.value))
    }
    
    //MARK: - Update
    
    func updateArtworkImageView() {
        self.artworkImageView.image = self.player.currentPlaybackItem?.albumImage
    }
    
    func updateSlider() {
        self.slider.minimumValue = 0
        self.slider.maximumValue = Float(self.player.duration ?? 0)
    }
    
    func updateInfoLabels() {
        self.titleLabel.text = "\(self.player.currentPlaybackItem?.artistName ?? "") - \(self.player.currentPlaybackItem?.trackName ?? "")"
        self.descriptionLabel.text = "\(self.player.currentPlaybackItem?.albumName ?? "")"
    }
    
    func updateTimeLabels() {
        if let currentTime = self.player.currentTime, duration = self.player.duration {
            self.elapsedTimeLabel.text = self.humanReadableTimeInterval(currentTime)
            self.remainingTimeLabel.text = "-" + self.humanReadableTimeInterval(duration - currentTime)
        }
        else {
            self.elapsedTimeLabel.text = ""
            self.remainingTimeLabel.text = ""
        }
    }
    
    func updateControls() {
        self.playPauseButton.selected = self.player.isPlaying
        self.nextButton.enabled = self.player.nextPlaybackItem != nil
        self.previousButton.enabled = self.player.previousPlaybackItem != nil
    }

    //MARK: - Convenience
    
    var player: LGAudioPlayer {
        return LGAudioPlayer.sharedPlayer
    }
    
    var playlist: [LGPlaybackItem] {
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
    }

    func humanReadableTimeInterval(timeInterval: NSTimeInterval) -> String {
        let timeInt = Int(round(timeInterval))
        let (hh, mm, ss) = (timeInt / 3600, (timeInt % 3600) / 60, (timeInt % 3600) % 60)
        
        let hhString: String? = hh > 0 ? String(hh) : nil
        let mmString = (hh > 0 && mm < 10 ? "0" : "") + String(mm)
        let ssString = (ss < 10 ? "0" : "") + String(ss)
        
        return (hhString != nil ? (hhString! + ":") : "") + mmString + ":" + ssString
    }

    //MARK: -

}
