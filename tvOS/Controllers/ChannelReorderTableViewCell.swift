//
//  ChannelReorderTableViewCell.swift
//  antenna
//
//  Created by Lucas Harding on 2016-05-04.
//  Copyright © 2016 Lucas Harding. All rights reserved.
//

import UIKit

open class ChannelReorderTableViewCell: UITableViewCell {
    @IBOutlet open var channelImageView: UIImageView!
    @IBOutlet open var favoriteImageView: UIImageView!
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        self.favoriteImageView.layer.shadowColor = UIColor.black.cgColor
        self.favoriteImageView.layer.shadowOpacity = 0.8
        self.favoriteImageView.layer.shadowOffset = CGSize(width: 0,height: 0)
        self.favoriteImageView.layer.shadowRadius = 10
    }
    
    open override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        
        coordinator.addCoordinatedAnimations({
            self.favoriteImageView.transform = (context.nextFocusedView == self) ? CGAffineTransform(translationX: 35, y: 0).scaledBy(x: 1.5, y: 1.5)  : CGAffineTransform.identity
            }, completion: nil)
    }
}
