
//
//  GuideCollectionViewController.swift
//  ustvnow-tvos
//
//  Created by Lucas Harding on 2015-09-11.
//  Copyright © 2015 Lucas Harding. All rights reserved.
//

import UIKit
import Alamofire

class GuideCollectionViewController: UIViewController, UICollectionViewDataSource, GuideCollectionViewDelegate {
    
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    var guide : TVGuide?
    var focusedTime: Date?
    var focusedIndexPath: IndexPath = IndexPath(item: 0, section: 0)
    var timer: Timer? { didSet { oldValue?.invalidate() } }
    
    //MARK: View
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        self.collectionView.register(GuideChannelCollectionViewHeader.self, forSupplementaryViewOfKind: "ChannelHeader", withReuseIdentifier: "ChannelHeader")
        self.collectionView.register(GuideChannelCollectionViewBackground.self, forSupplementaryViewOfKind: "ChannelBackground", withReuseIdentifier: "ChannelBackground")
        self.collectionView.register(GuideTimeCollectionViewHeader.self, forSupplementaryViewOfKind: "TimeHeader", withReuseIdentifier: "TimeHeader")
        self.collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: "TimeIndicator", withReuseIdentifier: "TimeIndicator")
        
        NotificationCenter.default.addObserver(self, selector: #selector(GuideCollectionViewController.didRefreshGuide(_:)), name: NSNotification.Name(rawValue: TVService.didRefreshGuideNotification), object: nil)
        self.didRefreshGuide(nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.timer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(GuideCollectionViewController.timerFire), userInfo: nil, repeats: true)
        self.timer?.fire()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.timer = nil
    }
    
    func timerFire() {
        self.collectionView.reloadData()
    }
    
    //MARK: Notifications
    
    func didRefreshGuide(_ n: Notification?) {
        if n != nil {
            self.activityIndicator.stopAnimating()
        }
        
        //Find previous focused channel and time
        var previousChannel: TVChannel?
        if (self.guide?.channels.count ?? 0) > self.focusedIndexPath.section {
            previousChannel = self.guide?.channels[self.focusedIndexPath.section]
        }
        
        //Update guide var
        self.guide = TVService.sharedInstance.guide
        self.guide?.channelsFilter = {
            return TVPreferences.sharedInstance.channelsFilterForGuide
        }
        
        //Update focused time if guide has shifted startdate
        if let startDate = self.guide?.startDate.addingTimeInterval(15 * 60) {
            self.focusedTime = (self.focusedTime as NSDate?)?.laterDate(startDate as Date)
        }
        
        //Try and focus new cell based on old focus
        if (previousChannel != nil) {
            let section = self.guide?.channels.index(of: previousChannel!)
            let item = self.focusedTime == nil ? 0 : self.guide?.programsForChannel(previousChannel!)?.index {
                return $0.containsDate(self.focusedTime!)
            }
            
            self.focusedIndexPath = IndexPath(item: item ?? 0, section: section ?? 0)
        }
        else {
            self.focusedIndexPath = IndexPath(item: 0, section: 0)
        }
        
        self.collectionView.reloadData()
        self.setNeedsFocusUpdate()
    }
    
    //MARK: UICollectionViewDataSource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.guide?.channels.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let channel = self.guide?.channels[section] else { return 0 }
        return self.guide?.programsForChannel(channel)?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell =  collectionView.dequeueReusableCell(withReuseIdentifier: "GuideProgramCollectionViewCell", for: indexPath) as! GuideProgramCollectionViewCell
        
        if let (_, program) = self.channelAndProgramForIndexPath(indexPath) {
            cell.titleLabel.text = program.title
            cell.subtitleLabel.text = program.episodeTitle
            cell.recordingBadge.isHidden = !program.isDVRScheduled
            cell.isAiring = program.isAiring
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: kind, for: indexPath)
        
        if kind == "ChannelHeader" {
            let header = view as! GuideChannelCollectionViewHeader
            if let channel = self.guide?.channels[indexPath.section] {
                header.imageView?.image = UIImage(named: channel.guideImageString)
            }
        }
        else if kind == "TimeHeader" {
            let header = view as! GuideTimeCollectionViewHeader
            
            if let date = self.guide?.startDate.addingTimeInterval(Double(1800 * indexPath.item)) {
                let dateFormatter = DateFormatter()
                dateFormatter.timeStyle = DateFormatter.Style.short
                
                header.titleLabel?.text = ((Calendar.current as NSCalendar).component(.minute, from: date as Date) == 0 || indexPath.item == 0) ? dateFormatter.string(from: date as Date) : ""
            }
            else {
                header.titleLabel?.text = ""
            }
        }
        else if kind == "TimeIndicator" {
            view.backgroundColor = UIColor(white: 1.0, alpha: 0.1)
        }
        
        return view
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let channel = self.guide?.channels[indexPath.section]
        let program = self.programForIndexPath(indexPath)
            
        if program?.isAiring == true && channel != nil {
            performSegue(withIdentifier: "PlayChannel", sender: channel)
        }
        else {
            performSegue(withIdentifier: "ShowProgramDetails", sender: program)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? PlayerViewController {
            controller.channel = sender as? TVChannel
        }
        else if let controller = segue.destination as? ProgramDetailsViewController {
            controller.program = sender as? TVProgram
        }
    }

    //MARK: GuideCollectionViewLayout Delegate
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, runtimeForProgramAtIndexPath indexPath: IndexPath) -> Double {
        guard let guide = self.guide, let (_, program) = self.channelAndProgramForIndexPath(indexPath) else { return 0 }
        return program.endDate.timeIntervalSince((guide.startDate as NSDate).laterDate(program.startDate as Date))
    }

    func timeIntervalForTimeIndicatorForCollectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout) -> Double {
        return self.guide?.startDate != nil ? Date().timeIntervalSince((self.guide?.startDate)! as Date) : 0
    }

    //MARK: Focus

    override var preferredFocusedView: UIView? {
        get {
            return self.collectionView.cellForItem(at: self.focusedIndexPath)
        }
    }
    
    func indexPathForPreferredFocusedView(in collectionView: UICollectionView) -> IndexPath? {
        return self.focusedIndexPath
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldUpdateFocusIn context: UICollectionViewFocusUpdateContext) -> Bool {
        if let indexPath = context.nextFocusedIndexPath {
            self.focusedIndexPath = indexPath
        }
        
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, didUpdateFocusIn context: UICollectionViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        if (context.focusHeading == .left || context.focusHeading == .right) || self.focusedTime == nil {
            //Keep track of approximate time of the focused cell, to make vertical scrolling smoother
            guard let indexPath = context.nextFocusedIndexPath, let (_, program) = self.channelAndProgramForIndexPath(indexPath) else { return }
            self.focusedTime = ((program.startDate.addingTimeInterval(60 * 15) as NSDate).earlierDate(program.endDate as Date) as NSDate).laterDate(self.guide!.startDate.addingTimeInterval(60 * 15) as Date)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, canFocusItemAt indexPath: IndexPath) -> Bool {
        if indexPath.section == self.focusedIndexPath.section {
            return true
        }
        else if indexPath.section == self.focusedIndexPath.section + 1 || indexPath.section == self.focusedIndexPath.section - 1 {
            //When vertical scrolling, try and find proper cell based on airtimes, instead of cell frames
            if let focusedTime = self.focusedTime {
                if let nextProgram = self.programForIndexPath(indexPath) {
                    if indexPath.item == 0 && self.focusedIndexPath.item == 0 {
                        return true
                    }
                    else if nextProgram.containsDate(focusedTime) {
                        return true
                    }
                    else {
                        return false
                    }
                }
            }
            else {
                return true
            }
        }
        
        return false
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        //Ensure the leftmost program cell is not cut off when focused
        
        guard let cell = UIScreen.main.focusedView as? UICollectionViewCell,
            let layout = self.collectionView.collectionViewLayout as? GuideCollectionViewLayout
        else { return }
        
        let point = targetContentOffset.pointee
        let leftPadding = CGFloat(layout.channelWidth + layout.padding)
        
        if point.x + leftPadding > cell.frame.minX {
            targetContentOffset.pointee = CGPoint(x: cell.frame.minX - leftPadding, y: point.y)
        }
    }
    
    //MARK: Helpers
    
    func channelAndProgramForIndexPath(_ indexPath: IndexPath?) -> (TVChannel, TVProgram)? {
        guard let indexPath = indexPath,
            let channel = self.guide?.channels[indexPath.section],
            let program = self.guide?.programsForChannel(channel)?[indexPath.item] else { return nil }
        
        return (channel, program)
    }
    
    func programForIndexPath(_ indexPath: IndexPath?) -> TVProgram? {
        guard let indexPath = indexPath, let channel = self.guide?.channels[indexPath.section] else { return nil }
        return self.guide?.programsForChannel(channel)?[indexPath.item]
    }
}
