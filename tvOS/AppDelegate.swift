//
//  AppDelegate.swift
//  ustvnow-tvos
//
//  Created by Lucas Harding on 2015-09-10.
//  Copyright © 2015 Lucas Harding. All rights reserved.
//

import UIKit
import AlamofireImage
import UserNotifications


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ app: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: TVService.didLogoutNotification), object: nil, queue: nil) {
            notification in
            self.window?.rootViewController = self.window?.rootViewController?.storyboard?.instantiateInitialViewController()
        }
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: TVService.didLoginNotification), object: nil, queue: nil) {
            notification in
            self.window?.rootViewController = self.window?.rootViewController?.storyboard?.instantiateViewController(withIdentifier: "Main")
        }
        
        self.window?.backgroundColor = UIColor(red:0.14, green:0.17, blue:0.20, alpha:1)
        UITabBar.appearance().backgroundColor = self.window?.backgroundColor
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        if components.host == "playChannel" {
            guard let streamCode = components.queryItems?.filter({ $0.name == "streamCode" }).first?.value,
                let guide = TVService.sharedInstance.guide else { return true }

            if let channel = guide.channelWithStreamCode(streamCode) {
                self.playChannel(channel)
            }
            else {
                guide.refresh() { _ in
                    if let channel = guide.channelWithStreamCode(streamCode) {
                        self.playChannel(channel)
                    }
                }
            }
        }

        return true
    }
    
    func playChannel(_ channel: TVChannel?) {
        guard let channel = channel,
            let tabBarController = self.window?.rootViewController as? UITabBarController,
            let controller = tabBarController.viewControllers?.first as? GuideCollectionViewController else { return }
        
        tabBarController.selectedIndex = 0
        controller.presentedViewController?.dismiss(animated: false, completion: nil)
        controller.performSegue(withIdentifier: "PlayChannel", sender: channel)
    }

}

