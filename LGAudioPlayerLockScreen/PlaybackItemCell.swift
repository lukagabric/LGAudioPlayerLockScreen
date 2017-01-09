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

    //MARK: - Vars
    
    let playbackItem: LGPlaybackItem
    var barsImageView: UIImageView?
    
    //MARK: - Dependencies
    
    let player: LGAudioPlayer
    
    //MARK: - Init
    
    init(player: LGAudioPlayer, playbackItem: LGPlaybackItem) {
        self.playbackItem = playbackItem
        self.player = player

        super.init(style: .subtitle, reuseIdentifier: nil)
        
        self.updateView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    //MARK: - Update View
    
    func updateView() {
        self.imageView?.image = UIImage(named: self.playbackItem.albumImageName)
        self.textLabel?.text = "\(self.playbackItem.artistName) - \(self.playbackItem.trackName)"
        self.detailTextLabel?.text = "\(self.playbackItem.albumName)"
        
        self.updateAccessoryView()
    }
    
    func updateAccessoryView() {
        self.barsImageView?.removeFromSuperview()
        
        if self.playbackItem == self.player.currentPlaybackItem {
            let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
            self.accessoryView = containerView
            
            let imageView = UIImageView(frame: CGRect(x: self.contentView.bounds.maxX + 5, y: self.contentView.bounds.midY - 10, width: 20, height: 20))
            
            imageView.contentMode = .scaleAspectFit
            self.addSubview(imageView)
            
            if self.player.isPlaying {
                var images = [UIImage]()
                for i in 1...9 {
                    images.append(UIImage(named: "bars\(i)")!)
                }
                
                imageView.animationImages = images
                imageView.animationDuration = 1
                imageView.startAnimating()
            }
            else {
                imageView.image = UIImage(named: "bars1")
            }
            
            self.barsImageView = imageView
        }
        else {
            self.accessoryView = nil
        }
    }
    
    //MARK: - Cell Selected/Highlighted
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        self.updateAccessoryView()
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        self.updateAccessoryView()
    }
    
}
