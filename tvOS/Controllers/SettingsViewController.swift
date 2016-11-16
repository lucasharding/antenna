//
//  SettingsViewController.swift
//  antenna
//
//  Created by Lucas Harding on 2016-02-01.
//  Copyright © 2016 Lucas Harding. All rights reserved.
//

import UIKit

class SettingsViewController : UITableViewController {
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white, NSFontAttributeName: UIFont.systemFont(ofSize: 57, weight: 0)]
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        cell.detailTextLabel?.alpha = 0.7
        
        switch indexPath.item {
        case 0:
            cell.textLabel?.text = "Guide"
            
            switch TVPreferences.sharedInstance.channelsFilterForGuide {
            case .All:
                cell.detailTextLabel?.text = "All Channels"
            case .Available:
                cell.detailTextLabel?.text = "Available Channels"
            case .Favorites:
                cell.detailTextLabel?.text = "Favorites"
            }
        case 1:
            cell.textLabel?.text = "Top Shelf"
            
            switch TVPreferences.sharedInstance.channelsFilterForTopShelf {
            case .All:
                cell.detailTextLabel?.text = "All Channels"
            case .Available:
                cell.detailTextLabel?.text = "Available Channels"
            case .Favorites:
                cell.detailTextLabel?.text = "Favorites"
            }
        default:
            break
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let pref = TVPreferences.sharedInstance
        switch indexPath.item {
        case 0:
            switch pref.channelsFilterForGuide {
            case .All:
                pref.channelsFilterForGuide = .Available
            case .Available:
                pref.channelsFilterForGuide = .Favorites
            case .Favorites:
                pref.channelsFilterForGuide = .All
            }
        case 1:
            switch pref.channelsFilterForTopShelf {
            case .All:
                pref.channelsFilterForTopShelf = .Available
            case .Available:
                pref.channelsFilterForTopShelf = .Favorites
            case .Favorites:
                pref.channelsFilterForTopShelf = .All
            }
        default:
            break
        }

        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
    
    @IBAction func logoutButtonPressed(_ sender: UIButton) {
        let controller = UIAlertController(title: "Are you sure you want to logout?", message: nil, preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: "Logout", style: .destructive) { _ in
            TVService.sharedInstance.logout()
        })
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(controller, animated: true, completion: nil)
    }
    
}

class SettingsTableViewCell : UITableViewCell {
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        
        coordinator.addCoordinatedAnimations({
            self.textLabel?.isHighlighted = context.nextFocusedView == self
            self.detailTextLabel?.isHighlighted = context.nextFocusedView == self
        }, completion: nil)
    }
    
}
