//
//  PlayerOverlayViewController.swift
//  antenna
//
//  Created by Lucas Harding on 2016-01-03.
//  Copyright © 2016 Lucas Harding. All rights reserved.
//

import UIKit
import Alamofire

class PlayerOverlayViewController : UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UIGestureRecognizerDelegate {
    
    //MARK: IBOutlets
    
    @IBOutlet var currentProgramTitleLabel: UILabel!
    @IBOutlet var currentProgramImageView: UIImageView!
    @IBOutlet var currentProgramImageViewHeight: NSLayoutConstraint!
    
    @IBOutlet var nextProgramCountdownLabel: UILabel!
    @IBOutlet var nextProgramTitleLabel: UILabel!
    @IBOutlet var nextProgramImageView: UIImageView!
    @IBOutlet var nextProgramImageViewHeight: NSLayoutConstraint!

    @IBOutlet var channelImageView: UIImageView!
    @IBOutlet var channelImageViewHeight: NSLayoutConstraint!
    
    @IBOutlet var collectionView: UICollectionView?

    @IBOutlet var containerView: UIView?
    @IBOutlet var containerViewBottomLayoutConstraint: NSLayoutConstraint?
    @IBOutlet var containerViewTopLayoutConstraint: NSLayoutConstraint?

    var channels: [TVChannel]?
    
    //MARK: View

    override var preferredFocusedView: UIView? {
        get {
            if let index = self.indexPathToFocus {
                return self.collectionView?.cellForItem(at: index)
            }
            return nil
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(PlayerOverlayViewController.panUpRecognizer(_:)))
        self.panRecognizer?.delegate = self
        self.view.addGestureRecognizer(self.panRecognizer!)
        
        self.collectionView?.reloadData()

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: TVService.didRefreshGuideNotification), object: nil, queue: nil) { _ in
            self.channels = TVService.sharedInstance.guide?.channels
            self.collectionView?.reloadData()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
            
        self.overlayTimer = nil
    }
    
    //MARK: View updating
    
    var channel: TVChannel?
    func updateWith(_ channel: TVChannel?) {
        if let channel = channel {
            self.channel = channel

            if let programs = TVService.sharedInstance.guide?.programsForChannel(channel) {
                if let index = programs.index(where: { $0.isAiring }) {
                    self.updateWithCurrentProgram(programs[index])
                    self.updateWithNextProgram(index + 1 < programs.count ? programs[index + 1] : nil)
                }
                else {
                    self.updateWithCurrentProgram(programs.first)
                    self.updateWithNextProgram(programs.count > 1 ? programs[1] : nil)
                }
            }
            
            if let image = UIImage(named: channel.guideImageString) {
                self.channelImageView.image = image
                self.channelImageViewHeight.constant = image.size.height / image.size.width * (channelImageView?.frame.size.width)!
            }
            
            if let index = self.channels?.index(of: channel) {
                self.indexPathToFocus = IndexPath(item: index, section: 0)
                
                if let collectionView = self.collectionView {
                    let animated = self.view?.window != nil ? self.view.window!.bounds.intersects(self.view.convert(collectionView.frame, to: self.view.window)) : false
                    collectionView.scrollToItem(at: self.indexPathToFocus!, at: .centeredHorizontally, animated: animated)
                }
            }
            
            self.setNeedsFocusUpdate()
        }
    }
    
    func updateWithCurrentProgram(_ program: TVProgram?) {
        guard let program = program else { return }

        let string = NSMutableAttributedString(string: program.title, attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 64)])
        if (program.episodeTitle.characters.count > 0) {
            string.append(NSAttributedString(string: "\n" + program.episodeTitle, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 54)]))
        }
        self.currentProgramTitleLabel.numberOfLines = 2
        self.currentProgramTitleLabel.attributedText = string
        
        self.updateImageView(self.currentProgramImageView, constraint: self.currentProgramImageViewHeight, withProgram: program)
    }
    
    func updateWithNextProgram(_ program: TVProgram?) {
        if let program = program {
            let minutes = Int(ceil(program.startDate.timeIntervalSinceNow / 60))
            self.nextProgramTitleLabel.text = program.title
            self.nextProgramCountdownLabel.text = "In \(minutes) minutes..."
            
            self.updateImageView(self.nextProgramImageView, constraint: self.nextProgramImageViewHeight, withProgram: program)
        }
    }
    
    func updateImageView(_ imageView: UIImageView, constraint: NSLayoutConstraint, withProgram program: TVProgram) {
        imageView.image = nil
        
        guard let imageURL = program.imageURL else { return }
        
        constraint.constant = CGFloat(0.75) * imageView.frame.size.width
        self.view.setNeedsUpdateConstraints()
        self.view.layoutIfNeeded()
        
        imageView.af_setImage(withURL: imageURL, placeholderImage: nil, filter: nil, imageTransition: UIImageView.ImageTransition.noTransition) {
            response in
            if let image = response.result.value {
                imageView.image = image
                constraint.constant = image.size.height / image.size.width * imageView.frame.size.width
            }
        }
    }
    
    //MARK: UICollectionView
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.channels?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        cell.clipsToBounds = false
        if let imageView = cell.contentView.subviews.first as? UIImageView {
            if let channel = self.channels?[indexPath.item] {
                imageView.image = UIImage(named: channel.topshelfImageString)
            }
        }
        return cell
    }
    
    var indexPathToFocus: IndexPath?
    func collectionView(_ collectionView: UICollectionView, shouldUpdateFocusIn context: UICollectionViewFocusUpdateContext) -> Bool {
        return context.focusHeading == .right || context.focusHeading == .left
    }
    func collectionView(_ collectionView: UICollectionView, didUpdateFocusIn context: UICollectionViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        self.indexPathToFocus = context.nextFocusedIndexPath
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime(uptimeNanoseconds: NSEC_PER_SEC/3)) {
            if let cell = UIScreen.main.focusedView as? UICollectionViewCell {
                if let indexPath = collectionView.indexPath(for: cell) {
                    if indexPath == self.indexPathToFocus {
                        if let channel = self.channels?[indexPath.item] {
                            self.updateWith(channel)
                        }
                    }
                }
            }
        }
    }
    func collectionView(_ collectionView: UICollectionView, canFocusItemAt indexPath: IndexPath) -> Bool {
        return (indexPath == self.indexPathToFocus) || (self.panRecognizer?.state == .possible)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if (self.panOffset != 0) {
            if let controller = self.parent as? PlayerViewController {
                controller.channel = self.channels?[indexPath.item]
            }
            self.setPanOffset(0, animated: true)
        }
    }
    
    //MARK: Panning
        
    var overlayTimer: Timer? { didSet { oldValue?.invalidate() } }
    var panOffset: Float = 0 {
        didSet {
            self.containerViewTopLayoutConstraint?.isActive = self.panOffset == 0
            self.containerViewBottomLayoutConstraint?.isActive = self.panOffset != 0
        
            self.containerViewBottomLayoutConstraint?.constant = min(0, CGFloat((self.containerView!.frame.size.height * CGFloat(self.panOffset)) - self.containerView!.frame.size.height))
            self.view.setNeedsUpdateConstraints()
            self.view.layoutIfNeeded()
        
            self.setNeedsFocusUpdate()
        }
    }
    func setPanOffset(_ offset: Float, animated: Bool = false, completion: (() -> Void)? = nil) {
        if (animated) {
            UIView.animate(withDuration: 0.3 * abs(Double(self.panOffset - offset)), delay: 0, options: .curveEaseIn, animations: {
                self.panOffset = offset
            }, completion: { _ in
                completion?()
            })
        }
        else {
            self.panOffset = offset
        }
    }
    
    var panOffsetThreshold: Float {
        return 1.0 - Float((self.collectionView!.frame.size.height + 20) / self.containerView!.frame.size.height)
    }

    var panRecognizer: UIPanGestureRecognizer?
    func panUpRecognizer(_ recognizer: UIPanGestureRecognizer) {
        self.overlayTimer = nil
        switch recognizer.state {

        case .changed:
            let offset = Float(-recognizer.translation(in: self.view).y / (self.view.frame.size.height * 0.5))
            self.panOffset = self.panOffset + offset
            recognizer.setTranslation(CGPoint(), in: self.view)
            break
        case .ended:
            if (self.panOffset >= 1 - ((1 - self.panOffsetThreshold) * 0.5)) {
                self.setPanOffset(1, animated: true)
            }
            else if(self.panOffset >= self.panOffsetThreshold * 0.5) {
                self.setPanOffset(self.panOffsetThreshold, animated: true)
            }
            else {
                self.setPanOffset(0, animated: true)
            }
            break
        default:
            break
        }
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let gestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
            let velocity = gestureRecognizer.velocity(in: self.view)
            return abs(velocity.y) > abs(velocity.x)
        }
        return true
    }

}
