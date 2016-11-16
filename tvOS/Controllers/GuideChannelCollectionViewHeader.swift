//
//  GuideChannelCollectionViewHeader.swift
//  ustvnow-tvos
//
//  Created by Lucas Harding on 2015-09-11.
//  Copyright © 2015 Lucas Harding. All rights reserved.
//

import UIKit

open class GuideChannelCollectionViewHeader : UICollectionReusableView {
    
    var imageView: UIImageView!
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    internal func commonInit() {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(imageView)
        self.imageView = imageView
        
        addConstraint(NSLayoutConstraint(item: imageView, attribute: .width, relatedBy: .equal, toItem: imageView, attribute: .height, multiplier: 1.0, constant: 0.0))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[imageView]-30-|", options: [], metrics: nil, views: ["imageView": imageView]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-20-[imageView]-20-|", options: [], metrics: nil, views: ["imageView": imageView]))
    }
    
}


open class GuideChannelCollectionViewBackground : UICollectionReusableView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    internal func commonInit() {
        let view = UIVisualEffectView(frame: self.bounds)
        view.effect = UIBlurEffect(style: .dark)
        view.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
        self.addSubview(view)
    }
}
