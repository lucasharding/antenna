//
//  RecordingsTableViewController.swift
//  antenna
//
//  Created by Lucas Harding on 2016-01-25.
//  Copyright © 2016 Lucas Harding. All rights reserved.
//

import UIKit

class RecordingsTableViewController : UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet var tableView: UITableView?
    var segmentedControl: UISegmentedControl?
    @IBOutlet var noResultsLabel: UILabel?
    
    var allRecordings: [TVRecording]?
    var recordings: [TVRecording]?
    
    //MARK: View
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.segmentedControl = UISegmentedControl(items: ["Recorded", "Scheduled"])
        self.segmentedControl?.selectedSegmentIndex = 0
        self.segmentedControl?.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor(white: 1, alpha: 0.3)], for: UIControlState())
        self.segmentedControl?.addTarget(self, action: #selector(RecordingsTableViewController.filterRecordings), for: .valueChanged)
        self.navigationItem.titleView = self.segmentedControl
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.checkFilteredSegment()
        
        TVService.sharedInstance.getRecordings { recordings, error in
            self.allRecordings = recordings
            self.filterRecordings()
            self.checkFilteredSegment()
        }
    }
    
    //MARK:
    
    func checkFilteredSegment() {
        if self.recordings?.count == 0 {
            if self.allRecordings?.count == 0 {
                self.segmentedControl?.selectedSegmentIndex = 0
            }
            else {
                self.segmentedControl?.selectedSegmentIndex = self.segmentedControl?.selectedSegmentIndex == 0 ? 1 : 0
            }
            self.filterRecordings()
        }
    }
    
    func filterRecordings() {
        if self.segmentedControl?.selectedSegmentIndex == 0 {
            self.noResultsLabel?.text = "No recorded programs."
            self.recordings = self.allRecordings?.filter({ $0.inPast })
        }
        else {
            self.noResultsLabel?.text = "No scheduled recordings."
            self.recordings = self.allRecordings?.filter({ !$0.inPast })
        }
        self.noResultsLabel?.isHidden = (self.recordings?.count ?? 0) > 0
        self.tableView?.reloadData()
    }
    
    //MARK: Table View
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.recordings?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! RecordingsTableViewCell
        cell.updateWithProgram(self.recordings?[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.gestureRecognizers?.forEach { cell.removeGestureRecognizer($0) }
        cell.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(RecordingsTableViewController.cellLongPressed(_:))))
    }
        
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let recording = self.recordings?[indexPath.row] else { return }
        if recording.inPast {
            performSegue(withIdentifier: "PlayRecording", sender: recording)
        }
        else {
            showMenuForRecording(recording)
        }
    }
    
    //MARK:
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? RecordingPlayerViewController {
            controller.recording = sender as? TVRecording
        }
    }
    
    func cellLongPressed(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            guard let cell = gesture.view as? UITableViewCell,
                let indexPath = self.tableView?.indexPath(for: cell),
                let recording = self.recordings?[indexPath.row] else { return }
            
            showMenuForRecording(recording)
        }
    }
    
    func showMenuForRecording(_ recording: TVRecording) {
        var title = recording.title
        if recording.episodeTitle.characters.count > 0 {
            title.append(" - \(recording.episodeTitle)")
        }
        
        let controller = UIAlertController(title: title, message: recording.description, preferredStyle: .actionSheet)
        
        if recording.isDVRScheduled == false {
            controller.addAction(UIAlertAction(title: "Play", style: .default) { a in
                self.performSegue(withIdentifier: "PlayRecording", sender: recording)
            })
        }
        
        controller.addAction(UIAlertAction(title: "Remove Recording", style: .destructive) { a in
            let controller = UIAlertController(title: "Are you sure you want to remove \(title)?", message: nil, preferredStyle: .actionSheet)
            
            controller.addAction(UIAlertAction(title: "Remove", style: .destructive) { a in
                TVService.sharedInstance.toggleProgramRecording(false, program: recording) { success, error in
                    if success {
                        if let index = self.allRecordings?.index(of: recording) {
                            self.allRecordings?.remove(at: index)
                        }
                        self.filterRecordings()
                    }
                    else {
                        let controller = UIAlertController(title: "An Error Occured", message: error?.localizedDescription, preferredStyle: .alert)
                        controller.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                        self.present(controller, animated: true, completion: nil)
                    }
                }
            })
            
            controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(controller, animated: true, completion: nil)
        })
        
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(controller, animated: true, completion: nil)
    }

}
