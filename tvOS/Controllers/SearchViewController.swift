//
//  SearchViewController.swift
//  antenna
//
//  Created by Lucas Harding on 2016-01-26.
//  Copyright © 2016 Lucas Harding. All rights reserved.
//

import UIKit
import AutoScrollLabel
import Alamofire

class SearchNavigationViewController : UINavigationController {
    
    override var preferredFocusedView: UIView? {
        get {
            if self.presentedViewController != nil {
                return self.presentedViewController?.view
            }
            return self.view
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let searchController = UISearchController(searchResultsController: self.viewControllers.first as? SearchViewController)
        searchController.searchResultsUpdater = searchController.searchResultsController as? UISearchResultsUpdating
        searchController.searchBar.keyboardAppearance = .dark
        searchController.searchBar.autocapitalizationType = .words
        searchController.searchBar.tintColor = UIColor.white
        searchController.view.backgroundColor = (UIApplication.shared.delegate as? AppDelegate)?.window?.backgroundColor
        
        self.viewControllers = [UISearchContainerViewController(searchController: searchController)]
    }
    
}

class SearchViewController : UICollectionViewController, UISearchResultsUpdating {
    
    lazy var dateFormatter: DateFormatter = {
       let f = DateFormatter()
        f.dateFormat = "MMMM dd, yyyy - h:mm a"
        return f
    }()
    
    var searchResults: [TVProgram]?
    var searchRequest: Request?
    func updateSearchResults(for searchController: UISearchController) {
        self.searchRequest?.cancel()

        if let term = searchController.searchBar.text {
            if term.characters.count > 0 {
                self.searchRequest = TVService.sharedInstance.getSearchResults(term) { results, _ in
                    self.searchResults = results
                    self.collectionView?.reloadData()
                }
            }
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.searchResults?.count ?? 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! SearchCollectionViewCell
        
        if let program = self.searchResults?[indexPath.item] {
            cell.titleLabel?.text = program.title
            cell.subtitleLabel?.text = self.dateFormatter.string(from: program.startDate as Date)
            
            if let imageURL = program.imageURL {
                cell.imageView?.af_setImage(withURL: imageURL)
            }
            else {
                cell.imageView?.image = nil
            }
        }
        
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard
            let controller = segue.destination as? ProgramDetailsViewController,
            let cell = sender as? UICollectionViewCell,
            let indexPath = self.collectionView?.indexPath(for: cell),
            let program = self.searchResults?[indexPath.item],
            let searchController = self.parent as? UISearchController
        else { return }
        
        controller.program = program
        searchController.navigationController?.setNeedsFocusUpdate()
    }
    
}

class SearchCollectionViewCell : UICollectionViewCell {
    
    @IBOutlet var imageView: UIImageView?
    @IBOutlet var titleOffset: NSLayoutConstraint?
    @IBOutlet var titleLabel: CBAutoScrollLabel?
    @IBOutlet var subtitleLabel: CBAutoScrollLabel?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.titleLabel?.textColor = UIColor.white
        self.titleLabel?.font = UIFont.boldSystemFont(ofSize: 28.0)
        self.titleLabel?.textAlignment = NSTextAlignment.center
        
        self.subtitleLabel?.textColor = UIColor.white
        self.subtitleLabel?.font = UIFont.systemFont(ofSize: 26.0)
        self.subtitleLabel?.textAlignment = NSTextAlignment.center
        
        self.titleLabel?.scrollSpeed = 0
        self.subtitleLabel?.scrollSpeed = 0
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.imageView?.image = nil
        self.titleLabel?.scrollSpeed = 0
        self.subtitleLabel?.scrollSpeed = 0
        self.titleLabel?.refreshLabels()
        self.subtitleLabel?.refreshLabels()
    }
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        
        self.titleLabel?.scrollSpeed = context.previouslyFocusedView != self ? 30 : 0
        self.subtitleLabel?.scrollSpeed = self.titleLabel?.scrollSpeed ?? 0
        self.titleLabel?.scrollLabelIfNeeded()
        self.subtitleLabel?.scrollLabelIfNeeded()
        
        coordinator.addCoordinatedAnimations({
            if context.previouslyFocusedView == self {
                self.titleLabel?.transform = CGAffineTransform.identity
            } else {
                self.titleLabel?.transform = CGAffineTransform(translationX: 0.0, y: 30.0)
            }
            self.subtitleLabel?.transform = self.titleLabel!.transform
        }, completion: nil)
    }
    
}
