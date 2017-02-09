//
//  TVPreferencesManager.swift
//  antenna
//
//  Created by Lucas Harding on 2016-02-07.
//  Copyright © 2016 Lucas Harding. All rights reserved.
//

import Foundation
import KeychainSwift

public enum TVChannelFilter: String {
    case All = "all"
    case Available = "available"
    case Favorites = "favorites"
}

open class TVPreferences {
    
    open static let sharedInstance: TVPreferences = {
        return TVPreferences()
    }()
    
    open static let sharedDefaults: UserDefaults = {
        //This is a way to get around self-signing breaking App Groups because of changing identifiers
        var appIdentifier = (Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String) ?? ""
        appIdentifier = appIdentifier.replacingOccurrences(of: ".topshelf", with: "")
        appIdentifier = appIdentifier.replacingOccurrences(of: ".topShelf", with: "")
        appIdentifier = appIdentifier.replacingOccurrences(of: ".top_shelf", with: "")
        
        let sharedDefaults = UserDefaults(suiteName: "group.\(appIdentifier)")!
        return sharedDefaults
    }()
    
    open static let keychain: KeychainSwift = {
        return KeychainSwift(keyPrefix: "antenna")
    }()
    
    init() {
    }
    
    //MARK:
    
    
    //TODO:
    open var accountToken: String? = {
        //return TVPreferences.keychain.get("account.token")
        return TVPreferences.sharedDefaults.string(forKey: "account.token")
    }(){
        didSet {
            //return TVPreferences.keychain.set("account.token", self.accountToken)
            TVPreferences.sharedDefaults.set(self.accountToken, forKey: "account.token")
            TVPreferences.sharedDefaults.synchronize()
        }
    }

    //MARK:
    
    open var channelsFilterForGuide: TVChannelFilter = {
        return TVChannelFilter(rawValue: TVPreferences.sharedDefaults.string(forKey: "channels.filter.guide") ?? "available") ?? .Available
    }(){
        didSet {
            TVPreferences.sharedDefaults.set(self.channelsFilterForGuide.rawValue, forKey: "channels.filter.guide")
            TVPreferences.sharedDefaults.synchronize()
        }
    }
    
    open var channelsFilterForTopShelf: TVChannelFilter = {
        return TVChannelFilter(rawValue: TVPreferences.sharedDefaults.string(forKey: "channels.filter.topShelf") ?? "available") ?? .Available
    }(){
        didSet {
            TVPreferences.sharedDefaults.set(self.channelsFilterForTopShelf.rawValue, forKey: "channels.filter.topShelf")
            TVPreferences.sharedDefaults.synchronize()
            
            NotificationCenter.default.post(name: NSNotification.Name.TVTopShelfItemsDidChange, object: nil)
        }
    }
    
    //MARK:

    open var channelsFavoritesKeys: [String] = {
        return (TVPreferences.sharedDefaults.object(forKey: "channels.favorites") as? [String]) ?? [String]()
    }(){
        didSet {
            TVPreferences.sharedDefaults.set(self.channelsFavoritesKeys, forKey: "channels.favorites")
            TVPreferences.sharedDefaults.synchronize()
            
            NotificationCenter.default.post(name: NSNotification.Name.TVTopShelfItemsDidChange, object: nil)
        }
    }
    
    open var channelsOrderKeys: [String] = {
        return (TVPreferences.sharedDefaults.object(forKey: "channels.order") as? [String]) ?? [String]()
    }(){
        didSet {
            TVPreferences.sharedDefaults.set(self.channelsOrderKeys, forKey: "channels.order")
            TVPreferences.sharedDefaults.synchronize()
            
            NotificationCenter.default.post(name: NSNotification.Name.TVTopShelfItemsDidChange, object: nil)
        }
    }

    //MARK:
    
    open func favoriteChannel(_ channel: TVChannel) -> Void {
        if let c = channel.streamCode {
            self.channelsFavoritesKeys = self.channelsFavoritesKeys + [c] //Has to trigger didSet
        }
    }
    
    open func unfavoriteChannel(_ channel: TVChannel) -> Void {
        if let c = channel.streamCode {
            self.channelsFavoritesKeys = self.channelsFavoritesKeys.filter({ $0 != c }) //Has to trigger didSet
        }
    }
    
    open func isFavoriteChannel(_ channel: TVChannel) -> Bool {
        if let c = channel.streamCode {
            return self.channelsFavoritesKeys.contains(c)
        }
        return false
    }
    
}
