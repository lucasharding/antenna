//
//  TVChannel.swift
//  ustvnow-tvos
//
//  Created by Lucas Harding on 2015-09-11.
//  Copyright © 2015 Lucas Harding. All rights reserved.
//

import Foundation
import ObjectMapper

open class TVChannel: Equatable, Mappable {
    
    var name : String = ""
    var available : Bool = false
    
    var streamCode : String?
    var callSign : String?
    
    var streamOrigin : String?
    var streamAppName : String?
    var streamName : String?
    
    public required init?(map: Map){
        
    }
    
    open func mapping(map: Map) {
        self.name <- map["stream_code"]
        self.available <- map["content_allowed"]
        
        self.streamCode <- map["scode"]
        self.callSign <- map["callsign"]
        
        self.streamOrigin <- map["stream_origin"]
        self.streamAppName <- map["app_name"]
        self.streamName <- map["streamname"]
    }
    
    var topshelfImageString: String {
        return "topshelf_\(self.name.lowercased().replacingOccurrences(of: " ", with: "_"))"
    }
    
    var guideImageString: String {
        return "guide_icon_\(self.name.lowercased().replacingOccurrences(of: " ", with: "_"))"
    }
    
}

public func ==(lhs: TVChannel, rhs: TVChannel) -> Bool {
    return lhs.streamCode == rhs.streamCode
}
