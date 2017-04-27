//
//  TVGuide.swift
//  ustvnow-tvos
//
//  Created by Lucas Harding on 2015-09-11.
//  Copyright © 2015 Lucas Harding. All rights reserved.
//

import Foundation
import ObjectMapper
import Alamofire
import AlamofireObjectMapper
import TVServices


open class TVGuide {
    
    var startDate : Date = Date()
    var endDate : Date = Date()

    var programs = Array<TVProgram>()
    var channels = Array<TVChannel>()

    var channelsFilter: ((Void) -> TVChannelFilter)?
    
    fileprivate var programsMap = [String: Array<TVProgram>]()
    open var allChannels = Array<TVChannel>()

    public init(startDate: Date = Date(), completionHandler: @escaping (TVGuide, Error?) -> Void) {
        NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: nil) { n in
            self.recalculate()
            NotificationCenter.default.post(name: Notification.Name(rawValue: TVService.didRefreshGuideNotification), object: nil)
        }
        
        refresh { (error) in
            completionHandler(self, error)
        }
    }
    

    //MARK: Refreshing
    
    @discardableResult open func refresh(_ completionHandler: @escaping (Error?) -> Void) -> Request {
        var channels = [TVChannel]()
        return TVService.sharedInstance.getPrograms(nil).responseArray(keyPath: "results") { (response: DataResponse<[TVChannel]>) in
            channels = response.result.value ?? channels
        }.responseArray(keyPath: "results") { (response: DataResponse<[TVProgram]>) in
            var endDate : Date?
            var channelsMap = [String: TVChannel]()
            
            var allChannels = [TVChannel]()
            var allPrograms = [TVProgram]()
            var programsMap = [String: [TVProgram]]()
            
            if let programs = response.result.value {
                for (index, program) in programs.enumerated() {
                    // Find or create channel
                    var channel = channelsMap[program.channelCode]
                    if channel == nil {
                        channel = channels[index]
                        
                        allChannels.append(channel!)
                        channelsMap[channel!.streamCode!] = channel
                    }
                    
                    // Find or create array of programs for channel
                    var programsForChannel = programsMap[channel!.streamCode!]
                    if programsForChannel == nil {
                        programsForChannel = Array<TVProgram>()
                    }
                    programsForChannel?.append(program)
                    
                    // Set new endDate if program endDate is later
                    if endDate == nil || program.endDate > endDate! {
                        endDate = program.endDate
                    }
                    
                    // Update respective collections
                    allPrograms.append(program)
                    programsMap[channel!.streamCode!] = programsForChannel
                }
                
            }

            TVImageService.sharedInstance.fillProgramImages(allPrograms) { _ in
                self.allChannels = allChannels
                self.programs = allPrograms
                self.programsMap = programsMap
                self.endDate = self.startDate.addingTimeInterval(3 * 3600)
                
                self.recalculate()
                
                DispatchQueue.main.async() {
                    completionHandler(response.result.error)
                }
                
                self.scheduleRefreshTimer()
            }
        }
    }
    
    open func recalculate() {
        //Round startdate to last half hour
        var units = Calendar.current.dateComponents([.day,.month,.year,.hour,.minute], from: Date())
        units.minute = (units.minute! / 30) * 30
        units.second = 1
        self.startDate = Calendar.current.date(from: units)!
        print("Recalculate", self.startDate)
        
        //Filter programs
        self.programs = self.programs.filter({ (self.startDate as NSDate).laterDate($0.endDate as Date) == $0.endDate as Date })
        for (key, programs) in self.programsMap {
            self.programsMap[key] = programs.filter({ (self.startDate as NSDate).laterDate($0.endDate as Date) == $0.endDate as Date })
        }
        
        var channels = self.allSortedChannels
        
        //Filter
        if self.channelsFilter != nil {
            if self.channelsFilter!() == .Favorites {
                channels = channels.filter({ TVPreferences.sharedInstance.isFavoriteChannel($0) })
            }
            else if self.channelsFilter!() == .Available {
                channels = channels.filter({ (channel) -> Bool in
                    return channel.available
                })
            }
        }
        
        self.channels = channels
        
        self.scheduleRecalcTimer()
        
        DispatchQueue.main.async { 
            NotificationCenter.default.post(name: Notification.Name(rawValue: TVService.didRefreshGuideNotification), object: nil)
            NotificationCenter.default.post(name: NSNotification.Name.TVTopShelfItemsDidChange, object: nil)
        }
    }
    
    
    //MARK: Accessors
    
    var allSortedChannels: [TVChannel] {
        get {
            var oldChannels = self.allChannels
            var channels = [TVChannel]()
            
            for streamCode in TVPreferences.sharedInstance.channelsOrderKeys {
                if let index = oldChannels.index(where: { return $0.streamCode == streamCode }) {
                    channels.append(oldChannels.remove(at: index))
                }
            }
            channels.append(contentsOf: oldChannels)
            
            return channels
        }
    }

    open func programsForChannel(_ channel: TVChannel) -> Array<TVProgram>? {
        return self.programsMap[channel.streamCode!]
    }
    
    open func channelWithStreamCode(_ streamCode: String) -> TVChannel? {
        for channel in self.channels {
            if channel.streamCode == streamCode {
                return channel
            }
        }
        
        return nil
    }
    
    //MARK: Timers
    
    var refreshTimer: Timer? { didSet { oldValue?.invalidate() } }
    func scheduleRefreshTimer() {
        let date = Date(timeIntervalSinceNow: 60 * 30)
        self.refreshTimer = Timer(fireAt: date, interval: 0, target: self, selector: #selector(TVGuide.timerFire), userInfo: nil, repeats: false)
        RunLoop.main.add(self.refreshTimer!, forMode: RunLoopMode.commonModes)
        
        print("** Scheduling refresh for:", date)
    }

    @objc func timerFire() {
        self.refresh {_ in }
    }

    var recalcTimer: Timer? { didSet { oldValue?.invalidate() } }
    func scheduleRecalcTimer() {
        var units = (Calendar.current as NSCalendar).components([.day,.month,.year,.hour,.minute], from: Date())
        units.minute = ((units.minute! + 30) / 30) * 30
        let date = Calendar.current.date(from: units)!
        self.recalcTimer = Timer(fireAt: date, interval: 0, target: self, selector:#selector(TVGuide.recalcTimerFire), userInfo: nil, repeats: false)
        RunLoop.main.add(self.recalcTimer!, forMode: RunLoopMode.commonModes)

        print("** Scheduling recalc for:", date)
    }

    @objc func recalcTimerFire() {
        self.recalculate()
    }
    
}
