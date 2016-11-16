//
//  RecordingsTableViewCell.swift
//  antenna
//
//  Created by Lucas Harding on 2016-05-03.
//  Copyright © 2016 Lucas Harding. All rights reserved.
//

import UIKit

class RecordingsTableViewCell : UITableViewCell {
    
    @IBOutlet var channelImageView: UIImageView?
    @IBOutlet var programImageView: UIImageView?
    @IBOutlet var titleLabel: UILabel?
    @IBOutlet var timesLabel: UILabel?
    @IBOutlet var expiresLabel: UILabel?
    @IBOutlet var descriptionLabel: UILabel?
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        
        let focused = context.nextFocusedView == self
        coordinator.addCoordinatedAnimations({
            self.titleLabel?.isHighlighted = focused
            self.timesLabel?.isHighlighted = focused
            self.descriptionLabel?.isHighlighted = focused
            self.expiresLabel?.isHighlighted = focused
        }, completion: nil)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.imageView?.image = nil
    }
    
    func updateWithProgram(_ program: TVRecording?) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        
        if let program = program {
            if let imageURL = program.imageURL {
                self.programImageView?.af_setImage(withURL: imageURL)
            }
            self.titleLabel?.text = program.title
            
            self.timesLabel?.text = "\(dateFormatter.string(from: program.startDate as Date)) • \(timeFormatter.string(from: program.startDate as Date)) • \(Int(program.runtime / 60)) mins"
            
            if program.isDVRScheduled == false && program.dvrExpiresAt != nil {
                self.expiresLabel?.text = "Expires: \(dateFormatter.string(from: program.dvrExpiresAt! as Date))"
            }
            else {
                self.expiresLabel?.text = nil
            }
            
            if program.episodeTitle.characters.count > 0 {
                self.descriptionLabel?.text = "\(program.episodeTitle) - \(program.description)"
            }
            else {
                self.descriptionLabel?.text = program.description
            }
        }
    }
    
}
