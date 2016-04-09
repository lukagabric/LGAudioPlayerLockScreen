//
//  PlaybackItemCell.swift
//  LGAudioPlayerLockScreen
//
//  Created by Luka Gabric on 10/04/16.
//  Copyright © 2016 Luka Gabric. All rights reserved.
//

import Foundation
import UIKit

class PlaybackItemCell: UITableViewCell {
    
    var playbackItem: LGPlaybackItem!
    var player: LGAudioPlayer {
        return LGAudioPlayer.sharedPlayer
    }
    var barsImageView: UIImageView?
    
    init(playbackItem: LGPlaybackItem) {
        self.playbackItem = playbackItem
        super.init(style: .Subtitle, reuseIdentifier: nil)
        self.updateView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func updateView() {
        self.imageView?.image = playbackItem.albumImage
        self.textLabel?.text = "\(playbackItem.artistName) - \(playbackItem.trackName)"
        self.detailTextLabel?.text = "\(playbackItem.albumName)"
        
        self.updateAccessoryView()
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        self.updateAccessoryView()
    }
    
    override func setHighlighted(highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        self.updateAccessoryView()
    }
    
    func updateAccessoryView() {
        self.barsImageView?.removeFromSuperview()
        
        if self.playbackItem == self.player.currentPlaybackItem {
            let containerView = UIView(frame: CGRectMake(0, 0, 30, 30))
            self.accessoryView = containerView
            
            let imageView = UIImageView(frame: CGRectMake(CGRectGetMaxX(self.contentView.bounds) + 5, CGRectGetMidY(self.contentView.bounds) - 15, 30, 30))
            
            imageView.contentMode = .ScaleAspectFit
            self.addSubview(imageView)
            
            if self.player.isPlaying {
                var images = [UIImage]()
                for i in 1...9 {
                    images.append(UIImage(named: "bars\(i)")!)
                }
                
                imageView.animationImages = images
                imageView.animationDuration = 1
                imageView.startAnimating()
            } else {
                imageView.image = UIImage(named: "bars1")
            }
            
            self.barsImageView = imageView
        } else {
            self.accessoryView = nil
        }
    }
    
}
