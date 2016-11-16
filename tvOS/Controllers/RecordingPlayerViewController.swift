//
//  RecordingPlayerViewController.swift
//  antenna
//
//  Created by Lucas Harding on 2016-01-25.
//  Copyright © 2016 Lucas Harding. All rights reserved.
//

import UIKit
import AVKit

class RecordingPlayerViewController : AVPlayerViewController {
    
    var recording: TVRecording? {
        didSet {
            if let recording = recording {
                TVImageService.sharedInstance.fillProgramImages([recording]) { _ in
                    TVService.sharedInstance.playRecording(recording) {
                        url in
                        if let url = url {
                            let asset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": ["User-Agent": TVService.sharedInstance.randomUserAgent]])
                            let mediaItem = AVPlayerItem(asset: asset)
                            
                            self.player = AVPlayer(playerItem: mediaItem)
                            self.player?.play()
                            
                            NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: mediaItem, queue: nil) { n in
                                self.dismiss(animated: true, completion: nil)
                            }
                        }
                    }
                }
            }
        }
    }
    
}
