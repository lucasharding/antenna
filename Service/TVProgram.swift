//
//  TVProgram.swift
//  ustvnow-tvos
//
//  Created by Lucas Harding on 2015-09-10.
//  Copyright © 2015 Lucas Harding. All rights reserved.
//

import Foundation
import ObjectMapper


open class TVProgram : Equatable, Mappable {
    
    var channelCode : String = ""
    var scheduleID : Int = 0
    var connectorID : String = ""
    
    var startDate : Date = Date()
    var endDate : Date = Date()
    var runtime : TimeInterval = 0
    
    var title : String = ""
    var episodeTitle : String = ""
    var synopsis : String = ""
    var description : String = ""
    
    var isDVRScheduled : Bool = false
    
    var imageURL : URL?
    var mediatype : String?
    
    var images: TVProgramImages?
    
    required public init?(map: Map){

    }
    
    open func mapping(map: Map) {
        self.channelCode <- map["scode"]
        self.connectorID <- (map["connectorid"], ConnectorIDTransform())
        self.scheduleID <- map["scheduleid"]

        self.runtime <- map["runtime"]
        self.startDate <- (map["ut_start"], DateTransform())
        self.endDate = startDate.addingTimeInterval(runtime)
        
        self.title <- (map["title"], UnescapeTransform())
        self.synopsis <- (map["synopsis"], UnescapeTransform())
        self.description <- (map["description"], UnescapeTransform())
        self.episodeTitle <- (map["episode_title"], UnescapeTransform())
        
        self.isDVRScheduled = (map["dvraction"].currentValue as? String) == "remove"
        self.mediatype <- map["mediatype"]
        
        if let srsID = map["srsid"].currentValue {
            if let callsign = map["callsign"].currentValue {
                self.imageURL = URL(string: "http://m.poster.static-ustvnow.com/\(srsID)/\(callsign)/\(mediatype ?? "SH")")
            }
        }
    }
    
    var isAiring : Bool {
        return self.containsDate(Date())
    }

    func containsDate(_ date: Date) -> Bool {
        return (self.startDate == date) || ((self.startDate as NSDate).earlierDate(date) == self.startDate && (self.endDate as NSDate).laterDate(date) == self.endDate && self.endDate != date)
    }
    
}

open class UnescapeTransform: TransformType {
    public typealias Object = String
    public typealias JSON = String
    
    open func transformFromJSON(_ value: Any?) -> Object? {
        return (value as? String)?.unescape()
    }
    
    open func transformToJSON(_ value: String?) -> String? {
        return value
    }
}

open class ConnectorIDTransform: TransformType {
    public typealias Object = String
    public typealias JSON = String
    
    open func transformFromJSON(_ value: Any?) -> Object? {
        return (value as? String)?.cleanConnectorID()
    }
    
    open func transformToJSON(_ value: String?) -> String? {
        return value
    }
}


public func ==(lhs: TVProgram, rhs: TVProgram) -> Bool {
    return lhs.startDate == rhs.startDate && lhs.scheduleID == rhs.scheduleID
}
