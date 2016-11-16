//
//  GuideTimeCollectionViewHeader.swift
//  ustvnow-tvos
//
//  Created by Lucas Harding on 2015-09-12.
//  Copyright © 2015 Lucas Harding. All rights reserved.
//

import UIKit

open class GuideTimeCollectionViewHeader : UICollectionReusableView {
    
    var titleLabel: UILabel!
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    fileprivate func commonInit() {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 38, weight: UIFontWeightLight)
        titleLabel.textColor = UIColor.white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(titleLabel)
        self.titleLabel = titleLabel
        
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-30-[titleLabel]-30-|", options: [], metrics: nil, views: ["titleLabel": titleLabel]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[titleLabel]-|", options: [], metrics: nil, views: ["titleLabel": titleLabel]))
    }
    
}
