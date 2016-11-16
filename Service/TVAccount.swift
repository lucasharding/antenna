//
//  TVAccount.swift
//  antenna
//
//  Created by Lucas Harding on 2016-01-28.
//  Copyright © 2016 Lucas Harding. All rights reserved.
//

import Foundation
import ObjectMapper

open class TVAccount : Mappable {
    
    var username: String?
    var firstName: String?
    var lastName: String?
    
    var needAccountActivation: Bool?
    var needAccountRenew: Bool?
    
    var subID: Int?
    var planID: Int?
    var planName: String?
    var isPlanFree: Bool?
    var dvrPoints: Int?
    
    var language: String?
    
    public required init?(map: Map){
        
    }
    
    open func mapping(map: Map) {
        self.username <- map["username"]
        self.firstName <- map["fname"]
        self.lastName <- map["lname"]
        
        self.needAccountActivation <- map["need_account_activation"]
        self.needAccountRenew <- map["need_account_renew"]
        
        self.subID <- map["sub_id"]
        self.planID <- map["plan_id"]
        self.planName <- map["plan_name"]
        self.isPlanFree <- map["plan_free"]
        self.dvrPoints <- map["points"]
        self.language <- map["language"]
    }
        
}
