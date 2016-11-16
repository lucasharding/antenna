//
//  GuideProgramCollectionViewCell.swift
//  ustvnow-tvos
//
//  Created by Lucas Harding on 2015-09-11.
//  Copyright © 2015 Lucas Harding. All rights reserved.
//

import UIKit

class GuideProgramCollectionViewCell : UICollectionViewCell {
  
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var recordingBadge: UIView!

    var isAiring: Bool = false{
        didSet {
            self.contentView.alpha = self.isAiring ? 1.0 : 0.5
            self.backgroundView?.backgroundColor = self.isAiring ? UIColor.white : UIColor(red:0.57, green:0.58, blue:0.6, alpha:1)
        }
    }
    
    internal override func awakeFromNib() {
        let backgroundView = UIView()
        backgroundView.layer.shadowColor = UIColor(white: 0, alpha: 0.2).cgColor
        backgroundView.layer.shadowOffset = CGSize(width: 0, height: 10)
        backgroundView.layer.shadowRadius = 10
        backgroundView.layer.shadowOpacity = 0.5
        backgroundView.layer.cornerRadius = 10
        backgroundView.backgroundColor = UIColor.white
        backgroundView.alpha = 0.0
        self.backgroundView = backgroundView
        
        self.titleLabel.textColor = UIColor.white
        self.subtitleLabel.textColor = UIColor.white
        self.titleLabel.highlightedTextColor = UIColor.black
        self.subtitleLabel.highlightedTextColor = UIColor.black

        self.recordingBadge.layer.cornerRadius = 10
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.titleLabel.isHighlighted = false
        self.subtitleLabel.isHighlighted = false
    }
    
    //MARK: Focus

    internal override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        
        let focused = context.nextFocusedView == self
        focused ? addGestureRecognizer(self.panGesture) : removeGestureRecognizer(self.panGesture)

        coordinator.addCoordinatedAnimations({
            self.transform = focused ? self.focusedTransform : CGAffineTransform.identity

            self.titleLabel.textColor = focused ? UIColor.black : UIColor.white
            self.subtitleLabel.textColor = focused ? UIColor.black : UIColor.white
            self.titleLabel.transform = CGAffineTransform.identity
            self.subtitleLabel.transform = CGAffineTransform.identity

            self.backgroundView?.alpha = focused ? 1.0 : 0.0
        }, completion: nil)
    }
    
    var focusedTransform: CGAffineTransform {
        let ratio = min((self.frame.size.height + 20) / self.frame.size.height, (self.frame.size.width + 60) / self.frame.size.width)
        return CGAffineTransform(scaleX: ratio, y: ratio)
    }
    
    //MARK: Parallax Effect

    var initialPanPosition: CGPoint?
    fileprivate lazy var panGesture: UIPanGestureRecognizer = {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(GuideProgramCollectionViewCell.panGesture(_:)))
        pan.cancelsTouchesInView = false
        return pan
    }()

    func panGesture(_ pan: UIPanGestureRecognizer) {
        //From: http://eeeee.io/2015/11/13/apple-tv-parallax-gesture.html

        switch pan.state {
            case .began:
                initialPanPosition = pan.location(in: contentView)
            case .changed:
                if let initialPanPosition = self.initialPanPosition {
                    let currentPosition = pan.location(in: self.contentView)
                    let offset = CGPoint(x: currentPosition.x - initialPanPosition.x, y: currentPosition.y - initialPanPosition.y)
                    let coefficient = self.parallaxCoefficient
                    
                    self.transform = self.focusedTransform.concatenating(CGAffineTransform(translationX: offset.x * coefficient.x, y: offset.y * parallaxCoefficient.y))
                    self.titleLabel.transform = CGAffineTransform(translationX: offset.x * -0.5 * coefficient.x, y: offset.y * -0.5 * coefficient.y)
                    self.subtitleLabel.transform = CGAffineTransform(translationX: offset.x * -0.5 * coefficient.x, y: offset.y * -0.5 * coefficient.y)
                }
            default:
                UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .beginFromCurrentState, animations: {
                    self.transform = self.focusedTransform
                    self.titleLabel.transform = CGAffineTransform.identity
                    self.subtitleLabel.transform = CGAffineTransform.identity
                },
                completion: nil)
        }
    }
    
    var parallaxCoefficient: CGPoint {
        return CGPoint(x: min(0.11, 1 / frame.size.width * 16), y: min(0.11, 1 / frame.size.height * 16))
    }
    
}

