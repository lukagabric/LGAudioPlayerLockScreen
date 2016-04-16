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

let LGAudioPlayerOnTrackChangedNotification = "LGAudioPlayerOnTrackChangedNotification"
let LGAudioPlayerOnPlaybackStateChangedNotification = "LGAudioPlayerOnPlaybackStateChangedNotification"

public struct LGPlaybackItem {
    let fileURL: NSURL
    let trackName: String
    let albumName: String
    let artistName: String
    let albumImageName: String
}

extension LGPlaybackItem: Equatable {}
public func ==(lhs: LGPlaybackItem, rhs: LGPlaybackItem) -> Bool {
    return lhs.fileURL.absoluteString == rhs.fileURL.absoluteString
}

public class LGAudioPlayer: NSObject, AVAudioPlayerDelegate {
    
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
    
    public var currentTime: NSTimeInterval? {
        return self.audioPlayer?.currentTime
    }

    public var duration: NSTimeInterval? {
        return self.audioPlayer?.duration
    }
    
    public var isPlaying: Bool {
        return self.audioPlayer?.playing ?? false
    }
    
    //MARK: - Dependencies
    
    let audioSession: AVAudioSession
    let commandCenter: MPRemoteCommandCenter
    let nowPlayingInfoCenter: MPNowPlayingInfoCenter
    let notificationCenter: NSNotificationCenter

    //MARK: - Init
    
    typealias LGAudioPlayerDependencies = (audioSession: AVAudioSession, commandCenter: MPRemoteCommandCenter, nowPlayingInfoCenter: MPNowPlayingInfoCenter, notificationCenter: NSNotificationCenter)
    
    init(dependencies: LGAudioPlayerDependencies) {
        self.audioSession = dependencies.audioSession
        self.commandCenter = dependencies.commandCenter
        self.nowPlayingInfoCenter = dependencies.nowPlayingInfoCenter
        self.notificationCenter = dependencies.notificationCenter
        
        super.init()
        
        try! self.audioSession.setCategory(AVAudioSessionCategoryPlayback)
        try! self.audioSession.setActive(true)
        

        self.configureCommandCenter()
    }
    
    //MARK: - Playback Commands

    public func playItems(playbackItems: [LGPlaybackItem], firstItem: LGPlaybackItem? = nil) {
        self.playbackItems = playbackItems
        
        if playbackItems.count == 0 {
            self.endPlayback()
            return
        }

        let playbackItem = firstItem ?? self.playbackItems!.first!
        
        self.playItem(playbackItem)
    }
    
    func playItem(playbackItem: LGPlaybackItem) {
        guard let audioPlayer = try? AVAudioPlayer(contentsOfURL: playbackItem.fileURL) else {
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
        
        self.commandCenter.previousTrackCommand.enabled = currentPlaybackItem != playbackItems.first!
        self.commandCenter.nextTrackCommand.enabled = currentPlaybackItem != playbackItems.last!
    }
    
    func configureCommandCenter() {
        self.commandCenter.playCommand.addTargetWithHandler { [weak self] event -> MPRemoteCommandHandlerStatus in
            guard let sself = self else { return .CommandFailed }
            sself.play()
            return .Success
        }

        self.commandCenter.pauseCommand.addTargetWithHandler { [weak self] event -> MPRemoteCommandHandlerStatus in
            guard let sself = self else { return .CommandFailed }
            sself.pause()
            return .Success
        }
        
        self.commandCenter.nextTrackCommand.addTargetWithHandler { [weak self] event -> MPRemoteCommandHandlerStatus in
            guard let sself = self else { return .CommandFailed }
            sself.nextTrack()
            return .Success
        }
        
        self.commandCenter.previousTrackCommand.addTargetWithHandler { [weak self] event -> MPRemoteCommandHandlerStatus in
            guard let sself = self else { return .CommandFailed }
            sself.previousTrack()
            return .Success
        }
        
    }
    
    //MARK: - Now Playing Info

    func updateNowPlayingInfoForCurrentPlaybackItem() {
        guard let audioPlayer = self.audioPlayer, currentPlaybackItem = self.currentPlaybackItem else {
            self.configureNowPlayingInfo(nil)
            return
        }

        var nowPlayingInfo = [MPMediaItemPropertyTitle: currentPlaybackItem.trackName,
                              MPMediaItemPropertyAlbumTitle: currentPlaybackItem.albumName,
                              MPMediaItemPropertyArtist: currentPlaybackItem.artistName,
                              MPMediaItemPropertyPlaybackDuration: audioPlayer.duration,
                              MPNowPlayingInfoPropertyPlaybackRate: NSNumber(float: 1.0)]
        
        if let image = UIImage(named: currentPlaybackItem.albumImageName) {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(image: image)
        }
        
        self.configureNowPlayingInfo(nowPlayingInfo)
        
        self.updateNowPlayingInfoElapsedTime()
    }
    
    func updateNowPlayingInfoElapsedTime() {
        guard var nowPlayingInfo = self.nowPlayingInfo, let audioPlayer = self.audioPlayer else { return }

        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(double: audioPlayer.currentTime);
        
        self.configureNowPlayingInfo(nowPlayingInfo)
    }
    
    func configureNowPlayingInfo(nowPlayingInfo: [String: AnyObject]?) {
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

    public func audioPlayerBeginInterruption(player: AVAudioPlayer) {
        self.notifyOnPlaybackStateChanged()
    }
    
    public func audioPlayerEndInterruption(player: AVAudioPlayer, withOptions flags: Int) {
        if AVAudioSessionInterruptionOptions(rawValue: UInt(flags)) == .ShouldResume {
            self.play()
        }
    }
    
    //MARK: - Convenience
    
    func notifyOnPlaybackStateChanged() {
        self.notificationCenter.postNotificationName(LGAudioPlayerOnPlaybackStateChangedNotification, object: self)
    }

    func notifyOnTrackChanged() {
        self.notificationCenter.postNotificationName(LGAudioPlayerOnTrackChangedNotification, object: self)
    }
    
    //MARK: -
    
}
