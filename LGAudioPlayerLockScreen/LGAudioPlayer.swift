//
//  AudioPlayer.swift
//  LGAudioPlayerLockScreen
//
//  Created by Luka Gabric on 07/04/16.
//  Copyright © 2016 Luka Gabric. All rights reserved.
//

import Foundation
import AVFoundation
import MediaPlayer

public struct LGPlaybackItem {
    let fileName: String
    let type: String
    let trackName: String
    let albumName: String
    let artistName: String
    let albumImage: UIImage
}

extension LGPlaybackItem: Equatable {}
public func ==(lhs: LGPlaybackItem, rhs: LGPlaybackItem) -> Bool {
    return lhs.fileName == rhs.fileName
}

public class LGAudioPlayer: NSObject, AVAudioPlayerDelegate {
    
    //MARK: - Static
    
    static var sharedPlayer = LGAudioPlayer()
    
    //MARK: - Vars
    
    var audioPlayer: AVAudioPlayer?
    public var playbackItems: [LGPlaybackItem]?
    public var currentPlaybackItem: LGPlaybackItem?
    public var nextPlaybackItem: LGPlaybackItem? {
        guard let playbackItems = self.playbackItems, currentPlaybackItem = self.currentPlaybackItem else { return nil }
        
        let nextItemIndex = playbackItems.indexOf(currentPlaybackItem)! + 1
        if nextItemIndex >= playbackItems.count { return nil }
        
        return playbackItems[nextItemIndex]
    }
    public var previousPlaybackItem: LGPlaybackItem? {
        guard let playbackItems = self.playbackItems, currentPlaybackItem = self.currentPlaybackItem else { return nil }
        
        let previousItemIndex = playbackItems.indexOf(currentPlaybackItem)! - 1
        if previousItemIndex < 0 { return nil }
        
        return playbackItems[previousItemIndex]
    }
    var nowPlayingInfo: [String : AnyObject]?
    
    var currentTime: NSTimeInterval? {
        return self.audioPlayer?.currentTime
    }

    var duration: NSTimeInterval? {
        return self.audioPlayer?.duration
    }
    
    var isPlaying: Bool {
        return self.audioPlayer?.playing ?? false
    }
    
    var onTrackChanged: (() -> Void)?
    var onPlaybackStateChanged: (() -> Void)?
    
    var nowPlayingInfoCenter: MPNowPlayingInfoCenter {
        return MPNowPlayingInfoCenter.defaultCenter()
    }

    //MARK: - Init
    
    override init() {
        try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        try! AVAudioSession.sharedInstance().setActive(true)
        
        super.init()
        
        self.configureCommandCenter()
    }
    
    //MARK: - Playback Commands

    public func playItems(playbackItems: [LGPlaybackItem]) {
        self.playbackItems = playbackItems
        
        if playbackItems.count == 0 {
            self.endPlayback()
            return
        }

        let playbackItem = self.playbackItems!.first!
        
        self.playItem(playbackItem)
    }
    
    func playItem(playbackItem: LGPlaybackItem) {
        let fileURL = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource(playbackItem.fileName, ofType: playbackItem.type)!)
        
        guard let audioPlayer = try? AVAudioPlayer(contentsOfURL: fileURL) else {
            self.endPlayback()
            return
        }
        
        audioPlayer.delegate = self
        audioPlayer.prepareToPlay()
        audioPlayer.play()
        
        self.audioPlayer = audioPlayer
        
        self.currentPlaybackItem = playbackItem
        
        self.updateNowPlayingInfoForCurrentPlaybackItem()
        self.updateCommandCenter()

        self.notifyOnTrackChanged()
    }
    
    public func togglePlayPause() {
        if self.isPlaying {
            self.pause()
        }
        else {
            self.play()
        }
    }
    
    public func play() {
        self.audioPlayer?.play()
        self.updateNowPlayingInfoElapsedTime()
        self.notifyOnPlaybackStateChanged()
    }
    
    public func pause() {
        self.audioPlayer?.pause()
        self.updateNowPlayingInfoElapsedTime()
        self.notifyOnPlaybackStateChanged()
    }
    
    public func nextTrack() {
        guard let nextPlaybackItem = self.nextPlaybackItem else { return }
        self.playItem(nextPlaybackItem)
        self.updateCommandCenter()
    }
    
    public func previousTrack() {
        guard let previousPlaybackItem = self.previousPlaybackItem else { return }
        self.playItem(previousPlaybackItem)
        self.updateCommandCenter()
    }
    
    public func seekTo(timeInterval: NSTimeInterval) {
        self.audioPlayer?.currentTime = timeInterval
        self.updateNowPlayingInfoElapsedTime()
    }
    
    //MARK: - Command Center

    func updateCommandCenter() {
        guard let playbackItems = self.playbackItems, currentPlaybackItem = self.currentPlaybackItem else { return }

        let commandCenter = MPRemoteCommandCenter.sharedCommandCenter()
        commandCenter.previousTrackCommand.enabled = currentPlaybackItem != playbackItems.first!
        commandCenter.nextTrackCommand.enabled = currentPlaybackItem != playbackItems.last!
    }
    
    func configureCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.sharedCommandCenter()
        
        commandCenter.playCommand.addTargetWithHandler { [weak self] event -> MPRemoteCommandHandlerStatus in
            guard let sself = self else { return .CommandFailed }
            sself.play()
            return .Success
        }

        commandCenter.pauseCommand.addTargetWithHandler { [weak self] event -> MPRemoteCommandHandlerStatus in
            guard let sself = self else { return .CommandFailed }
            sself.pause()
            return .Success
        }
        
        commandCenter.nextTrackCommand.addTargetWithHandler { [weak self] event -> MPRemoteCommandHandlerStatus in
            guard let sself = self else { return .CommandFailed }
            sself.nextTrack()
            return .Success
        }
        
        commandCenter.previousTrackCommand.addTargetWithHandler { [weak self] event -> MPRemoteCommandHandlerStatus in
            guard let sself = self else { return .CommandFailed }
            sself.previousTrack()
            return .Success
        }
        
    }
    
    //MARK: - Now Playing Info

    func updateNowPlayingInfoForCurrentPlaybackItem() {
        guard let audioPlayer = self.audioPlayer, currentPlaybackItem = self.currentPlaybackItem else {
            self.nowPlayingInfo = nil
            self.nowPlayingInfoCenter.nowPlayingInfo = self.nowPlayingInfo
            return
        }

        self.nowPlayingInfo = [MPMediaItemPropertyTitle: currentPlaybackItem.trackName,
                               MPMediaItemPropertyAlbumTitle: currentPlaybackItem.albumName,
                               MPMediaItemPropertyArtist: currentPlaybackItem.artistName,
                               MPMediaItemPropertyArtwork: MPMediaItemArtwork(image: currentPlaybackItem.albumImage),
                               MPMediaItemPropertyPlaybackDuration: audioPlayer.duration,
                               MPNowPlayingInfoPropertyPlaybackRate: NSNumber(float: 1.0)]
        
        self.updateNowPlayingInfoElapsedTime()
    }
    
    func updateNowPlayingInfoElapsedTime() {
        guard var nowPlayingInfo = self.nowPlayingInfo, let audioPlayer = self.audioPlayer else { return }

        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(double: audioPlayer.currentTime);
        self.nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
        
        self.nowPlayingInfo = nowPlayingInfo
    }
    
    //MARK: - AVAudioPlayerDelegate
    
    public func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        if self.nextPlaybackItem == nil {
            self.endPlayback()
        }
        else {
            self.nextTrack()
        }
    }
    
    func endPlayback() {
        self.currentPlaybackItem = nil
        self.audioPlayer = nil
        
        self.updateNowPlayingInfoForCurrentPlaybackItem()
        self.notifyOnTrackChanged()
    }

    public func audioPlayerEndInterruption(player: AVAudioPlayer, withOptions flags: Int) {
        if AVAudioSessionInterruptionOptions(rawValue: UInt(flags)) == .ShouldResume {
            self.play()
        }
    }
    
    //MARK: - Convenience
    
    func notifyOnPlaybackStateChanged() {
        if let onPlaybackStateChanged = self.onPlaybackStateChanged {
            onPlaybackStateChanged()
        }
    }

    func notifyOnTrackChanged() {
        if let onTrackChanged = self.onTrackChanged {
            onTrackChanged()
        }
    }
    
    //MARK: -
    
}
