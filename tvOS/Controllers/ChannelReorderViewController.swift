//
//  ChannelReorderViewController.swift
//  antenna-tvos
//
//  Created by Lucas Harding on 2015-10-31.
//  Copyright © 2015 Lucas Harding. All rights reserved.
//

import UIKit

class ChannelReorderViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet var tableView: UITableView!
    
    var movingIndexPath: IndexPath?
    var focusUpdateBlockCheck: Bool = true
    var channels: Array<TVChannel>?
    
    //MARK: View
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationWillResignActive, object: nil, queue: nil) { _ in
            if let channels = self.channels {
                TVPreferences.sharedInstance.channelsOrderKeys = channels.map({ $0.streamCode ?? "" })
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.channels = TVService.sharedInstance.guide?.allSortedChannels
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let channels = self.channels {
            TVPreferences.sharedInstance.channelsOrderKeys = channels.map({ $0.streamCode ?? "" })
        }
    }
    
    //MARK: UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.channels?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return configureCell(tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ChannelReorderTableViewCell, indexPath: indexPath)
    }

    //MARK: UITableViewDelegate

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 44
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.movingIndexPath = self.movingIndexPath == nil ? indexPath : nil
        
        UIView.animate(withDuration: 0.3, animations: {
            tableView.visibleCells.forEach { cell in
                guard let reorderCell = cell as? ChannelReorderTableViewCell, let indexPath = tableView.indexPath(for: cell) else { return }
                self.configureCell(reorderCell, indexPath: indexPath)
            }
        }) 
    }
    
    //Kind of hacky way to piggy back on focus system, to reorder cells
    func tableView(_ tableView: UITableView, shouldUpdateFocusIn context: UITableViewFocusUpdateContext) -> Bool {
        if (self.movingIndexPath != nil) {
            if (self.focusUpdateBlockCheck) {
                let oldMovingIndexPath = self.movingIndexPath!
                
                if (context.focusHeading == .down && oldMovingIndexPath.row < channels!.count - 1) {
                    movingIndexPath = IndexPath(row: oldMovingIndexPath.row + 1, section: oldMovingIndexPath.section)
                }
                else if (context.focusHeading == .up && oldMovingIndexPath.row > 0) {
                    movingIndexPath = IndexPath(row: oldMovingIndexPath.row - 1, section: oldMovingIndexPath.section)
                }
                
                if let channel = channels?[oldMovingIndexPath.row] {
                    if let movingIndexPath = self.movingIndexPath {
                        self.channels!.remove(at: oldMovingIndexPath.row)
                        self.channels!.insert(channel, at: movingIndexPath.row)
                        
                        tableView.moveRow(at: oldMovingIndexPath, to: movingIndexPath)
                        tableView.scrollToRow(at: movingIndexPath, at: .middle, animated: true)
                    }
                }
                
                //Hack to avoid this delegate method getting called multiple times for same focus change
                self.focusUpdateBlockCheck = false
                DispatchQueue.main.async {
                    self.focusUpdateBlockCheck = true
                }
            }
            
            return false
        }

        return true
    }

    func tableView(_ tableView: UITableView, didUpdateFocusIn context: UITableViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        if (context.nextFocusedIndexPath == nil) {
            self.movingIndexPath = nil
            for cell in tableView.visibleCells {
                if let reorderCell = cell as? ChannelReorderTableViewCell {
                    if let indexPath = tableView.indexPath(for: cell) {
                        self.configureCell(reorderCell, indexPath: indexPath)
                    }
                }
            }
        }
    }
    
    func longPressRecognizer(_ recognizer: UILongPressGestureRecognizer) {
        guard let cell = recognizer.view as? ChannelReorderTableViewCell,
            let indexPath = self.tableView.indexPath(for: cell),
            let channel = self.channels?[indexPath.item] else { return }
        
        if recognizer.state == .began {
            if (TVPreferences.sharedInstance.isFavoriteChannel(channel)) {
                TVPreferences.sharedInstance.unfavoriteChannel(channel)
            }
            else {
                TVPreferences.sharedInstance.favoriteChannel(channel)
            }
            self.configureCell(cell, indexPath: indexPath)
        }
    }
    
    //MARK: Helper
    
    @discardableResult func configureCell(_ cell: ChannelReorderTableViewCell, indexPath: IndexPath) -> ChannelReorderTableViewCell {
        cell.clipsToBounds = false
        cell.gestureRecognizers?.forEach { cell.removeGestureRecognizer($0) }
        cell.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(ChannelReorderViewController.longPressRecognizer(_:))))
        
        if let channel = self.channels?[indexPath.row] {
            cell.channelImageView.image = UIImage(named: channel.topshelfImageString)
            cell.channelImageView.alpha = (self.movingIndexPath == nil || indexPath == self.movingIndexPath) ? 1.0 : 0.5
            cell.favoriteImageView.isHidden = TVPreferences.sharedInstance.isFavoriteChannel(channel) == false
        }
        
        return cell
    }

}
