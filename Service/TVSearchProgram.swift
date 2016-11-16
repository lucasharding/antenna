//
//  TVSearchProgram.swift
//  antenna
//
//  Created by Lucas Harding on 2016-01-26.
//  Copyright © 2016 Lucas Harding. All rights reserved.
//

import Foundation
import ObjectMapper

open class TVSearchProgram : TVProgram {
    
    required public init?(map: Map){
        super.init(map: map)
    }
    
    override open func mapping(map: Map) {
        super.mapping(map: map)
        
        self.connectorID <- (map["connid"], ConnectorIDTransform())
        self.scheduleID <- map["schid"]
        
        self.runtime <- map["duration"]
        self.endDate <- (map["ute"], DateTransform())
        self.startDate = endDate.addingTimeInterval(-1 * (self.runtime))
        
        if let srsID = map["srsid"].currentValue {
            if let callsign = map["scode"].currentValue {
                let mediaType = map["mediatype"].currentValue as? String
                self.imageURL = URL(string: "http://m.poster.static-ustvnow.com/\(srsID)/\(callsign)/\(mediaType ?? "SH")")
            }
        }
    }
    
}
