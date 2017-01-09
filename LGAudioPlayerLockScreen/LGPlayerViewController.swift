//
//  LGPlayerViewController.swift
//  LGAudioPlayerLockScreen
//
//  Created by Luka Gabric on 07/04/16.
//  Copyright © 2016 Luka Gabric. All rights reserved.
//

import UIKit

class LGPlayerViewController: UIViewController {
    
    //MARK: - Vars
    
    var timer: Timer?

    @IBOutlet weak var artworkImageView: UIImageView!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var previousButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var elapsedTimeLabel: UILabel!
    @IBOutlet weak var remainingTimeLabel: UILabel!
    
    //MARK: - Dependencies
    
    let player: LGAudioPlayer
    let notificationCenter: NotificationCenter
    
    //MARK: - Init
    
    typealias LGPlayerViewControllerDependencies = (player: LGAudioPlayer, notificationCenter: NotificationCenter)

    init(dependencies: LGPlayerViewControllerDependencies) {
        self.player = dependencies.player
        self.notificationCenter = dependencies.notificationCenter

        super.init(nibName: nil, bundle: nil)
        
        self.configureNotifications()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    deinit {
        self.notificationCenter.removeObserver(self)
        self.timer?.invalidate()
    }
    
    //MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.updateView()
        
        self.configureTimer()
    }
    
    //MARK: - Notifications
    
    func configureNotifications() {
        self.notificationCenter.addObserver(self, selector: #selector(onTrackChanged), name: NSNotification.Name(rawValue: LGAudioPlayerOnTrackChangedNotification), object: nil)
        self.notificationCenter.addObserver(self, selector: #selector(onPlaybackStateChanged), name: NSNotification.Name(rawValue: LGAudioPlayerOnPlaybackStateChangedNotification), object: nil)
    }
    
    func onTrackChanged() {
        if !self.isViewLoaded { return }
        
        if self.player.currentPlaybackItem == nil {
            self.close()
            return
        }
        
        self.updateView()
    }
    
    func onPlaybackStateChanged() {
        if !self.isViewLoaded { return }
        
        self.updateControls()
    }

    //MARK: - Configuration

    func configureTimer() {
        self.timer = Timer.every(0.1.seconds) { [weak self] in
            guard let sself = self else { return }
            
            if !sself.slider.isTracking {
                sself.slider.value = Float(sself.player.currentTime ?? 0)
            }
            
            sself.updateTimeLabels()
        }
    }
    
    //MARK: - Actions
    
    @IBAction func playPauseButtonAction(_ sender: AnyObject) {
        self.player.togglePlayPause()
    }
    
    @IBAction func previousButtonAction(_ sender: AnyObject) {
        self.player.previousTrack()
    }
    
    @IBAction func nextButtonAction(_ sender: AnyObject) {
        self.player.nextTrack()
    }
    
    @IBAction func swipeLeftAction(_ sender: AnyObject) {
        if self.player.nextPlaybackItem == nil {
            self.animateNoNextTrackBounce(self.artworkImageView.layer)
            return
        }

        self.animateContentChange(kCATransitionFromRight, layer: self.artworkImageView.layer)
        self.player.nextTrack()
    }

    @IBAction func swipeRightAction(_ sender: AnyObject) {
        if self.player.previousPlaybackItem == nil {
            self.animateNoPreviousTrackBounce(self.artworkImageView.layer)
            return
        }

        self.animateContentChange(kCATransitionFromLeft, layer: self.artworkImageView.layer)
        self.player.previousTrack()
    }
    
    @IBAction func sliderValueChanged(_ sender: AnyObject) {
        self.player.seekTo(Double(self.slider.value))
    }
    
    @IBAction func closeAction(_ sender: AnyObject) {
        self.close()
    }
    
    func close() {
        self.dismiss(animated: true, completion: nil)
    }
    
    //MARK: - Update
    
    func updateView() {
        self.updateArtworkImageView()
        self.updateSlider()
        self.updateInfoLabels()
        self.updateTimeLabels()
        self.updateControls()
    }
    
    func updateArtworkImageView() {
        self.artworkImageView.image = UIImage(named: self.player.currentPlaybackItem?.albumImageName ?? "")
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
        if let currentTime = self.player.currentTime, let duration = self.player.duration {
            self.elapsedTimeLabel.text = self.humanReadableTimeInterval(currentTime)
            self.remainingTimeLabel.text = "-" + self.humanReadableTimeInterval(duration - currentTime)
        }
        else {
            self.elapsedTimeLabel.text = ""
            self.remainingTimeLabel.text = ""
        }
    }
    
    func updateControls() {
        self.playPauseButton.isSelected = self.player.isPlaying
        self.nextButton.isEnabled = self.player.nextPlaybackItem != nil
        self.previousButton.isEnabled = self.player.previousPlaybackItem != nil
    }

    //MARK: - Convenience
    
    func humanReadableTimeInterval(_ timeInterval: TimeInterval) -> String {
        let timeInt = Int(round(timeInterval))
        let (hh, mm, ss) = (timeInt / 3600, (timeInt % 3600) / 60, (timeInt % 3600) % 60)
        
        let hhString: String? = hh > 0 ? String(hh) : nil
        let mmString = (hh > 0 && mm < 10 ? "0" : "") + String(mm)
        let ssString = (ss < 10 ? "0" : "") + String(ss)
        
        return (hhString != nil ? (hhString! + ":") : "") + mmString + ":" + ssString
    }
    
    func animateContentChange(_ transitionSubtype: String, layer: CALayer) {
        let transition = CATransition()
     
        transition.duration = 0.25
        transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        transition.type = kCATransitionPush
        transition.subtype = transitionSubtype

        layer.add(transition, forKey: kCATransition)
    }
    
    func animateNoPreviousTrackBounce(_ layer: CALayer) {
        self.animateBounce(fromValue: NSNumber(value: 0 as Int), toValue: NSNumber(value: 25 as Int), layer: layer)
    }
    
    func animateNoNextTrackBounce(_ layer: CALayer) {
        self.animateBounce(fromValue: NSNumber(value: 0 as Int), toValue: NSNumber(value: -25 as Int), layer: layer)
    }
    
    func animateBounce(fromValue: NSNumber, toValue: NSNumber, layer: CALayer) {
        let animation = CABasicAnimation(keyPath: "transform.translation.x")
        animation.fromValue = fromValue
        animation.toValue = toValue
        animation.duration = 0.1
        animation.repeatCount = 1
        animation.autoreverses = true
        animation.isRemovedOnCompletion = true
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        
        layer.add(animation, forKey: "Animation")
    }

    //MARK: -

}
