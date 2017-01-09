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
    let fileURL: URL
    let trackName: String
    let albumName: String
    let artistName: String
    let albumImageName: String
}

extension LGPlaybackItem: Equatable {}
public func ==(lhs: LGPlaybackItem, rhs: LGPlaybackItem) -> Bool {
    return lhs.fileURL.absoluteString == rhs.fileURL.absoluteString
}

open class LGAudioPlayer: NSObject, AVAudioPlayerDelegate {
    
    //MARK: - Vars
    
    var audioPlayer: AVAudioPlayer?
    open var playbackItems: [LGPlaybackItem]?
    open var currentPlaybackItem: LGPlaybackItem?
    open var nextPlaybackItem: LGPlaybackItem? {
        guard let playbackItems = self.playbackItems, let currentPlaybackItem = self.currentPlaybackItem else { return nil }
        
        let nextItemIndex = playbackItems.index(of: currentPlaybackItem)! + 1
        if nextItemIndex >= playbackItems.count { return nil }
        
        return playbackItems[nextItemIndex]
    }
    open var previousPlaybackItem: LGPlaybackItem? {
        guard let playbackItems = self.playbackItems, let currentPlaybackItem = self.currentPlaybackItem else { return nil }
        
        let previousItemIndex = playbackItems.index(of: currentPlaybackItem)! - 1
        if previousItemIndex < 0 { return nil }
        
        return playbackItems[previousItemIndex]
    }
    var nowPlayingInfo: [String : AnyObject]?
    
    open var currentTime: TimeInterval? {
        return self.audioPlayer?.currentTime
    }

    open var duration: TimeInterval? {
        return self.audioPlayer?.duration
    }
    
    open var isPlaying: Bool {
        return self.audioPlayer?.isPlaying ?? false
    }
    
    //MARK: - Dependencies
    
    let audioSession: AVAudioSession
    let commandCenter: MPRemoteCommandCenter
    let nowPlayingInfoCenter: MPNowPlayingInfoCenter
    let notificationCenter: NotificationCenter

    //MARK: - Init
    
    typealias LGAudioPlayerDependencies = (audioSession: AVAudioSession, commandCenter: MPRemoteCommandCenter, nowPlayingInfoCenter: MPNowPlayingInfoCenter, notificationCenter: NotificationCenter)
    
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

    open func playItems(_ playbackItems: [LGPlaybackItem], firstItem: LGPlaybackItem? = nil) {
        self.playbackItems = playbackItems
        
        if playbackItems.count == 0 {
            self.endPlayback()
            return
        }

        let playbackItem = firstItem ?? self.playbackItems!.first!
        
        self.playItem(playbackItem)
    }
    
    func playItem(_ playbackItem: LGPlaybackItem) {
        guard let audioPlayer = try? AVAudioPlayer(contentsOf: playbackItem.fileURL) else {
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
    
    open func togglePlayPause() {
        if self.isPlaying {
            self.pause()
        }
        else {
            self.play()
        }
    }
    
    open func play() {
        self.audioPlayer?.play()
        self.updateNowPlayingInfoElapsedTime()
        self.notifyOnPlaybackStateChanged()
    }
    
    open func pause() {
        self.audioPlayer?.pause()
        self.updateNowPlayingInfoElapsedTime()
        self.notifyOnPlaybackStateChanged()
    }
    
    open func nextTrack() {
        guard let nextPlaybackItem = self.nextPlaybackItem else { return }
        self.playItem(nextPlaybackItem)
        self.updateCommandCenter()
    }
    
    open func previousTrack() {
        guard let previousPlaybackItem = self.previousPlaybackItem else { return }
        self.playItem(previousPlaybackItem)
        self.updateCommandCenter()
    }
    
    open func seekTo(_ timeInterval: TimeInterval) {
        self.audioPlayer?.currentTime = timeInterval
        self.updateNowPlayingInfoElapsedTime()
    }
    
    //MARK: - Command Center

    func updateCommandCenter() {
        guard let playbackItems = self.playbackItems, let currentPlaybackItem = self.currentPlaybackItem else { return }
        
        self.commandCenter.previousTrackCommand.isEnabled = currentPlaybackItem != playbackItems.first!
        self.commandCenter.nextTrackCommand.isEnabled = currentPlaybackItem != playbackItems.last!
    }
    
    func configureCommandCenter() {
        self.commandCenter.playCommand.addTarget (handler: { [weak self] event -> MPRemoteCommandHandlerStatus in
            guard let sself = self else { return .commandFailed }
            sself.play()
            return .success
        })

        self.commandCenter.pauseCommand.addTarget (handler: { [weak self] event -> MPRemoteCommandHandlerStatus in
            guard let sself = self else { return .commandFailed }
            sself.pause()
            return .success
        })
        
        self.commandCenter.nextTrackCommand.addTarget (handler: { [weak self] event -> MPRemoteCommandHandlerStatus in
            guard let sself = self else { return .commandFailed }
            sself.nextTrack()
            return .success
        })
        
        self.commandCenter.previousTrackCommand.addTarget (handler: { [weak self] event -> MPRemoteCommandHandlerStatus in
            guard let sself = self else { return .commandFailed }
            sself.previousTrack()
            return .success
        })
        
    }
    
    //MARK: - Now Playing Info

    func updateNowPlayingInfoForCurrentPlaybackItem() {
        guard let audioPlayer = self.audioPlayer, let currentPlaybackItem = self.currentPlaybackItem else {
            self.configureNowPlayingInfo(nil)
            return
        }

        var nowPlayingInfo = [MPMediaItemPropertyTitle: currentPlaybackItem.trackName,
                              MPMediaItemPropertyAlbumTitle: currentPlaybackItem.albumName,
                              MPMediaItemPropertyArtist: currentPlaybackItem.artistName,
                              MPMediaItemPropertyPlaybackDuration: audioPlayer.duration,
                              MPNowPlayingInfoPropertyPlaybackRate: NSNumber(value: 1.0 as Float)] as [String : Any]
        
        if let image = UIImage(named: currentPlaybackItem.albumImageName) {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(image: image)
        }
        
        self.configureNowPlayingInfo(nowPlayingInfo as [String : AnyObject]?)
        
        self.updateNowPlayingInfoElapsedTime()
    }
    
    func updateNowPlayingInfoElapsedTime() {
        guard var nowPlayingInfo = self.nowPlayingInfo, let audioPlayer = self.audioPlayer else { return }

        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(value: audioPlayer.currentTime as Double);
        
        self.configureNowPlayingInfo(nowPlayingInfo)
    }
    
    func configureNowPlayingInfo(_ nowPlayingInfo: [String: AnyObject]?) {
        self.nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
        self.nowPlayingInfo = nowPlayingInfo        
    }
    
    //MARK: - AVAudioPlayerDelegate
    
    open func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
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

    open func audioPlayerBeginInterruption(_ player: AVAudioPlayer) {
        self.notifyOnPlaybackStateChanged()
    }
    
    open func audioPlayerEndInterruption(_ player: AVAudioPlayer, withOptions flags: Int) {
        if AVAudioSessionInterruptionOptions(rawValue: UInt(flags)) == .shouldResume {
            self.play()
        }
    }
    
    //MARK: - Convenience
    
    func notifyOnPlaybackStateChanged() {
        self.notificationCenter.post(name: Notification.Name(rawValue: LGAudioPlayerOnPlaybackStateChangedNotification), object: self)
    }

    func notifyOnTrackChanged() {
        self.notificationCenter.post(name: Notification.Name(rawValue: LGAudioPlayerOnTrackChangedNotification), object: self)
    }
    
    //MARK: -
    
}
