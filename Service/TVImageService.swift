
//
//  TVImageService.swift
//  antenna
//
//  Created by Lucas Harding on 2016-01-29.
//  Copyright © 2016 Lucas Harding. All rights reserved.
//

import Foundation
import Alamofire

class TVImageService {
    
    static let sharedInstance: TVImageService = {
        return TVImageService()
    }()

    let manager: SessionManager = {
       let config = URLSessionConfiguration.default
        config.timeoutIntervalForResource = 5
        
        return SessionManager(configuration: config)
    }()
    
    let baseURL = URL(string: "http://ntna-service.herokuapp.com/api")!
    
    init() {
    }
    
    
    @discardableResult func fillProgramImages(_ programs: [TVProgram], callback: @escaping ([TVProgram]) -> Void) -> Request? {
        let programs = programs.filter({ program in
            if let dict = self.cachedProgramImageJSON(program.connectorID) {
                program.images = TVProgramImages(json: dict)
                return false
            }
            return true
        }).sorted(by: {
            $0.connectorID.compare($1.connectorID) == ComparisonResult.orderedAscending
        })
                
        if programs.count > 0 {
            let params = ["connector_ids": programs.map({ $0.connectorID }).joined(separator: ",")]
            
            return self.manager.request(self.baseURL.appendingPathComponent("metadata"), method: .get, parameters: params).responseJSON() { response in

                if let json = response.result.value as? [AnyObject] {
                    var map = [String: TVProgramImages]()
                    json.forEach { e in
                        if e is NSDictionary {
                            let o = TVProgramImages(json: e as! NSDictionary)
                            
                            if let id = o.connectorID {
                                self.cacheProgramImageJSON(id, json: e as! NSDictionary)
                                map[id] = o
                            }
                        }
                    }
                    
                    for program in programs {
                        if let o = map[program.connectorID] {
                            program.images = o
                        }
                    }
                }

                callback(programs)
            }
        }
        else {
            callback(programs)
            return nil
        }
    }
    
    //MARK: Caching
    
    var programImagesCacheMap = [String: NSDictionary]()
    
    @discardableResult func cacheProgramImageJSON(_ connectorID: String, json: NSDictionary) -> Bool {
        self.programImagesCacheMap[connectorID] = json
        return false
    }
    func cachedProgramImageJSON(_ connectorID: String) -> NSDictionary? {
        if let json = self.programImagesCacheMap[connectorID] {
            return json
        }
        return nil
    }
    
    //MARK: Helper
    
}

open class TVProgramImages {
    
    var connectorID: String?
    
    var logoImageURL: URL?
    var posterImageURL: URL?
    var thumbImageURL: URL?
    var backgroundImageURL: URL?
    
    init(json: NSDictionary) {
        self.connectorID = json["connector_id"] as? String
        
        if let url = json["logo_image_url"] as? String {
            self.logoImageURL = URL(string: url.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlFragmentAllowed)!)
        }
        if let url = json["poster_image_url"] as? String {
            self.posterImageURL = URL(string: url.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlFragmentAllowed)!)
        }
        if let url = json["thumb_image_url"] as? String {
            self.thumbImageURL = URL(string: url.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlFragmentAllowed)!)
        }
        if let url = json["background_image_url"] as? String {
            self.backgroundImageURL = URL(string: url.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlFragmentAllowed)!)
        }
    }
    
}
