//
//  ServiceProvider.swift
//  tvos-extension
//
//  Created by Lucas Harding on 2015-09-11.
//  Copyright © 2015 Lucas Harding. All rights reserved.
//

import Foundation
import TVServices
import Alamofire

class ServiceProvider: NSObject, TVTopShelfProvider {

    var contentItem: TVContentItem?
    var lastRefresh: Date?
    var currentRequest: Request?
    
    override init() {
        super.init()
        
        self.currentRequest = TVService.sharedInstance.getAccount { _ in
            self.lastRefresh = Date()
        }
        NotificationCenter.default.post(name: NSNotification.Name.TVTopShelfItemsDidChange, object: nil)
    }

    // MARK: - TVTopShelfProvider protocol

    var topShelfStyle: TVTopShelfContentStyle {
        return .sectioned
    }

    var topShelfItems: [TVContentItem] {
        if self.currentRequest?.task?.state != .running && (self.lastRefresh == nil || (self.lastRefresh?.timeIntervalSinceNow ?? 0) < -(60 * 15)) {
            self.currentRequest = TVService.sharedInstance.guide?.refresh { _ in
                self.lastRefresh = Date()
            }
        }
        
        TVService.sharedInstance.guide?.channelsFilter = {
            return TVPreferences.sharedInstance.channelsFilterForTopShelf
        }
        TVService.sharedInstance.guide?.recalculate()
        
        guard let contentIdentifier = TVContentIdentifier(identifier: "com.antenna.channels", container: nil),
            let topItem = TVContentItem(contentIdentifier: contentIdentifier) else { return [TVContentItem]() }
        
        topItem.title = "Channels"
        let channels = TVService.sharedInstance.guide?.channels
        
        topItem.topShelfItems = channels?.flatMap({ (channel: TVChannel) -> TVContentItem? in
            let identifier = "\(topItem.contentIdentifier.identifier).\(channel.streamCode ?? "")"
            guard let contentIdentifier = TVContentIdentifier(identifier: identifier, container: topItem.contentIdentifier), let contentItem = TVContentItem(contentIdentifier: contentIdentifier) else { return nil }
            
            contentItem.title = channel.name
            
            contentItem.imageShape = .HDTV
            if let program = TVService.sharedInstance.guide?.programsForChannel(channel)?.first {
                contentItem.title = contentItem.title! + " - \(program.title)"
                
                if program.images?.thumbImageURL != nil {
                    contentItem.imageURL = program.images?.thumbImageURL
                }
                else if program.images?.posterImageURL != nil {
                    contentItem.imageURL = program.images?.posterImageURL
                    contentItem.imageShape = .poster
                }
                else if program.mediatype == "MV" {
                    contentItem.imageURL = program.images?.posterImageURL ?? program.imageURL
                    contentItem.imageShape = .poster
                }
            }
            
            if contentItem.imageURL == nil {
                contentItem.imageURL = Bundle.main.url(forResource: channel.topshelfImageString, withExtension: "png")
            }
            
            var comp = URLComponents(string: "antenna://playChannel")
            comp?.queryItems = [URLQueryItem(name: "streamCode", value: channel.streamCode)]
            
            contentItem.displayURL = comp?.url
            contentItem.playURL = contentItem.displayURL
            
            return contentItem
        })
        
        return [topItem]
    }

}
