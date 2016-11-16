//
//  TVRecording.swift
//  antenna
//
//  Created by Lucas Harding on 2016-01-26.
//  Copyright © 2016 Lucas Harding. All rights reserved.
//

import Foundation
import ObjectMapper

open class TVRecording : TVProgram {
    
    var dvrLocation: String?
    var dvrFilenameSMIL: String?
    var dvrExpiresAt: Date?
    
    required public init?(map: Map){
        super.init(map: map)
    }
    
    open override func mapping(map: Map) {
        super.mapping(map: map)
        
        self.connectorID <- (map["connectorid"], ConnectorIDTransform())
        
        self.dvrExpiresAt <- (map["ut_expires"], DateTransform())
        
        self.isDVRScheduled = (map["event_inprogres"].currentValue as? Int) != 0
        self.dvrLocation <- map["dvrlocation"]
        self.dvrFilenameSMIL <- map["filename_smil"]
    }
    
    var inPast: Bool {
        return self.endDate.timeIntervalSinceNow < 0
    }
    
}
