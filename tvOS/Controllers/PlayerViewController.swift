//
//  PlayerViewController.swift
//  ustvnow-tvos
//
//  Created by Lucas Harding on 2015-09-11.
//  Copyright © 2015 Lucas Harding. All rights reserved.
//

import UIKit
import AVFoundation
import Alamofire

//MARK: - PlayerViewController


open class PlayerViewController : UIViewController, UIGestureRecognizerDelegate {
        
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var playerView: PlayerLayerWrapperView?

        var activityTimer: Timer? { didSet { oldValue?.invalidate() } }

    lazy var upgradeViewController: PlayerUpgradeViewController = {
        let controller = self.storyboard!.instantiateViewController(withIdentifier: "PlayerUpgrade") as! PlayerUpgradeViewController
        controller.view.frame = self.view.frame
        self.view.addSubview(controller.view)
        self.addChildViewController(controller)
        return controller
    }()

    lazy var overlayViewController: PlayerOverlayViewController = {
        let controller = self.storyboard!.instantiateViewController(withIdentifier: "PlayerOverlay") as! PlayerOverlayViewController
        controller.view.frame = self.view.frame
        self.addChildViewController(controller)
        self.view.addSubview(controller.view)
        return controller
    }()
    
    open var player: AVPlayer? {
        didSet {
            self.playerView?.player = self.player
        }
    }
    open var channel: TVChannel? {
        didSet {
            self.view.isHidden = false
            self.overlayViewController.channel = self.channel

            if let channel = self.channel {
                self.upgradeViewController.imageView.image = UIImage(named: channel.guideImageString)
                self.upgradeViewController.titleLabel.text = "\(channel.name) is unavailable"
                self.upgradeViewController.view.isHidden = channel.available

                if channel.available {
                    if channel.streamName != oldValue?.streamName {
                        TVService.sharedInstance.playChannel(channel) { url in
                            if let url = url {
                                let asset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": ["User-Agent": TVService.sharedInstance.randomUserAgent]])
                                self.player = AVPlayer(playerItem: AVPlayerItem(asset: asset))
                                self.player?.play()
                            }
                            else {
                                self.player = nil
                            }
                        }
                    }
                }
                else {
                    self.player = nil
                }
            }
            else {
                self.player = nil
            }
        }
    }
    
    override open var preferredFocusedView: UIView? { get { return self.overlayViewController.view } }

    //MARK: View
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(self.upgradeViewController.view)
        self.view.addSubview(self.overlayViewController.view)
        
        let playTapRecognizer = UITapGestureRecognizer(target: self, action:#selector(PlayerViewController.didPressPlay(_:)))
        playTapRecognizer.allowedPressTypes = [NSNumber(value: UIPressType.playPause.rawValue as Int)];
        self.view.addGestureRecognizer(playTapRecognizer)
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.activityTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(PlayerViewController.activityTimerTick), userInfo: nil, repeats: true)
        self.showOverlay()
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.activityTimer = nil
    }
    
    //MARK: Other
    
    func didPressPlay(_ recognizer: UITapGestureRecognizer) {
        self.player?.rate = self.player?.rate == 1 ? 0.0 : 1.0
    }

    fileprivate func showOverlay() {
        self.view.isHidden = false
        self.overlayViewController.channels = TVService.sharedInstance.guide?.channels
        self.overlayViewController.updateWith(self.channel)
        self.overlayViewController.setPanOffset(self.overlayViewController.panOffsetThreshold)
        self.overlayViewController.overlayTimer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(PlayerViewController.hideOverlay), userInfo: nil, repeats: false)
    }
    
    @objc fileprivate func hideOverlay() {
        self.overlayViewController.setPanOffset(0, animated: true)
    }

    @objc fileprivate func activityTimerTick() {
        if (self.player == nil || (self.player?.currentItem?.loadedTimeRanges.count ?? 0) > 0 && self.player?.currentItem?.isPlaybackLikelyToKeepUp == true) {
            activityIndicator.stopAnimating()
        }
        else {
            activityIndicator.startAnimating()
        }
    }
    
}

class PlayerLayerWrapperView: UIView {
    
    var playerLayer: AVPlayerLayer?
    var player: AVPlayer? {
        get {
            return self.playerLayer?.player
        }
        set {
            self.playerLayer?.player = newValue
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.playerLayer = AVPlayerLayer()
        self.layer.addSublayer(self.playerLayer!)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.playerLayer?.frame = self.bounds
    }
    
}
