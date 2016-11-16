//
//  TVService.swift
//  ustvnow-tvos
//
//  Created by Lucas Harding on 2015-09-10.
//  Copyright © 2015 Lucas Harding. All rights reserved.
//

import Foundation

import Alamofire
import AlamofireImage
import AlamofireObjectMapper
import Kanna


open class TVService {
    
    //MARK: Constants

    open static let didLoginNotification = "TVServiceDidLoginNotification"
    open static let didLogoutNotification = "TVServiceDidLogoutNotification"
    open static let didRefreshGuideNotification = "TVServiceDidRefreshGuideNotification"

    fileprivate let baseURL = URL(string: "http://m-api.ustvnow.com/gtv/1/")!
    fileprivate let baseLoginURL = URL(string: "http://m.ustvnow.com/iphone/1/")!

    //MARK: Vars

    fileprivate var token: String? {
        get { return TVPreferences.sharedInstance.accountToken }
        set { TVPreferences.sharedInstance.accountToken = newValue }
    }
    
    open var isLoggedIn: Bool { get { return token != nil } }
    fileprivate var isLoginVerified: Bool = false {
        didSet {
            if (oldValue == false && isLoginVerified == true) {
                self.guide = TVGuide() { _ in }
                NotificationCenter.default.post(name: Notification.Name(rawValue: TVService.didLoginNotification), object: nil)
            }
        }
    }
    
    open var currentAccount: TVAccount?
    open var guide: TVGuide?

    //MARK: -
    
    var randomUserAgent: String {
        get {
            let userAgents = [
                "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_1) AppleWebKit/601.2.5 (KHTML, like Gecko) Version/9.0.1 Safari/601.2.5",
                "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/47.0.2526.111 Safari/537.36",
                "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/601.3.9 (KHTML, like Gecko) Version/9.0.2 Safari/537.86.3",
            ]
            
            let randomIndex = Int(arc4random_uniform(UInt32(userAgents.count)))
            return userAgents[randomIndex]
        }
    }
    
    lazy var manager: SessionManager = {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
        configuration.httpAdditionalHeaders?["User-Agent"] = self.randomUserAgent
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 30
        
        return SessionManager(configuration: configuration)
    }()
    
    open static let sharedInstance: TVService = {
        return TVService()
    }()

    public init() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationDidBecomeActive, object: nil, queue: nil) { n in
            self.guide?.refresh { _ in }
        }
    }
    
    //MARK: -

    @discardableResult open func login(_ username: String, password: String, completionHandler: @escaping (TVAccount?, Error?) -> Void) -> Request {
        
        return self.manager.request(self.baseLoginURL.appendingPathComponent("live/settings"), method: .get).responseString {
            response in
            
            var token: String?
            if let html = response.result.value {
                if let start = html.range(of: "csrftok=")?.upperBound {
                    if let end = html.range(of: "\"", options: [], range: start..<html.endIndex)?.lowerBound {
                        token = html.substring(with: start..<end)
                    }
                }
            }
            
            if (token != nil) {
                let params = ["username": username, "password": password, "device": "iphone"]

                let url = self.baseLoginURL.appendingPathComponent("live/login")
                self.manager.request(url.absoluteString + "?csrftok=\(token!)", method: .post, parameters: params).responseData {
                    response in
                    
                    var token: String?
                    if let responseHeaders = response.response?.allHeaderFields as? [String: String] {
                        let cookies = HTTPCookie.cookies(withResponseHeaderFields: responseHeaders, for: response.response!.url!)
                        token = cookies.filter({c in return c.name == "token"}).first?.value
                    }
                    
                    if (token != nil) {
                        self.token = token
                        self.getAccount(completionHandler)
                    }
                    else {
                        self.token = nil
                        self.guide = nil
                        self.isLoginVerified = false
                        completionHandler(nil, response.result.error ?? NSError(domain: "com.antenna", code: 0, userInfo: ["NSLocalizedDescription": "Email or password incorrect"]))
                    }
                }
            }
            else {
                self.token = nil
                self.guide = nil
                self.isLoginVerified = false
                completionHandler(nil, response.result.error ?? NSError(domain: "com.antenna", code: 0, userInfo: ["NSLocalizedDescription": "CSRF token invalid"]))
            }
        }
    }
    
    open func logout() {
        self.guide = nil
        self.currentAccount = nil
        
        self.isLoginVerified = false
        self.token = nil
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: TVService.didRefreshGuideNotification), object: nil)
        NotificationCenter.default.post(name: Notification.Name(rawValue: TVService.didLogoutNotification), object: nil)
    }
    
    @discardableResult open func getAccount(_ completionHandler: @escaping (TVAccount?, Error?) -> Void) -> DataRequest {
        return self.manager.request(self.baseURL.appendingPathComponent("live/getuserbytoken"), method: .get, parameters: ["token": self.token ?? ""]).responseObject(keyPath: "data", completionHandler: { (response: DataResponse<TVAccount>) in
            
            self.currentAccount = response.result.value
            self.isLoginVerified = response.result.error == nil && response.result.value?.needAccountActivation == false
            
            completionHandler(response.result.value, response.result.error)
        })
    }
    
    @discardableResult open func getPrograms(_ completionHandler: (([TVProgram]?, Error?) -> Void)?) -> DataRequest {
        let params = ["l": 1440 as AnyObject, "format": "rtmp" as AnyObject, "token": (self.token as AnyObject? ?? "" as AnyObject)] as [String: AnyObject]

        return self.manager.request(self.baseURL.appendingPathComponent("live/channelguide"), method: .get, parameters: params).responseArray(keyPath: "results") { (response: DataResponse<[TVProgram]>) in
            completionHandler?(response.result.value, response.result.error)
        }
    }
    
    @discardableResult open func playChannel(_ channel: TVChannel, completionHandler: @escaping (URL?) -> Void) -> DataRequest {
        let params = ["streamname": channel.streamName ?? "", "stream_origin": channel.streamOrigin ?? "", "app_name": channel.streamAppName ?? "", "token": token ?? "", "passkey": "tbd", "extrato": "tbd"]
        
        return self.manager.request(self.baseURL.appendingPathComponent("live/viewlive"), method: .get, parameters: params).responseHTMLDocument  { r in
            if let string = r.result.value?.at_css("video")?["src"] {
                completionHandler(URL(string: string))
            }
            else {
                completionHandler(nil)
            }
        }
    }
    
    //MARK: DVR
    
    @discardableResult open func toggleProgramRecording(_ record: Bool, program: TVProgram, completionHandler: @escaping (Bool, Error?) -> Void) -> DataRequest {
        let params = ["action": record ? "add" : "remove", "token": token ?? "", "scheduleid": program.scheduleID, "_": Date().timeIntervalSince1970] as [String : Any]
        
        return self.manager.request(self.baseURL.appendingPathComponent("dvr/updatedvr"), method: .get, parameters: params).responseXMLDocument {
            response in
            
            if response.result.value?.at_css("result status")?.text == "success" {
                program.isDVRScheduled = record
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: TVService.didRefreshGuideNotification), object: self.guide)
                completionHandler(true, nil)
            }
            else {
                var error = response.result.error
                
                if (error == nil) {
                    var errorMessage = "An error occured."
                    if record && self.currentAccount != nil && (self.currentAccount?.dvrPoints == 0 || self.currentAccount?.isPlanFree == true) {
                        errorMessage = "To record, please upgrade your account or invite friends to earn DVR credits."
                    }
                    error = NSError(domain: "com.antenna", code: 0, userInfo: ["NSLocalizedDescription": errorMessage])
                }
                
                completionHandler(false, error)
            }
        }
    }
    
    @discardableResult open func getRecordings(_ completionHandler: @escaping ([TVRecording]?, Error?) -> Void) -> Request {
        return self.manager.request(self.baseURL.appendingPathComponent("dvr/viewdvrlist"), method: .get, parameters: ["token": token ?? ""]).responseArray(keyPath: "results") {
            (r: DataResponse<[TVRecording]>) in
            completionHandler(r.result.value, r.result.error)
        }
    }

    @discardableResult open func playRecording(_ recording: TVRecording, completionHandler: @escaping (URL?) -> Void) -> Request {
        let params = ["streamname": recording.dvrFilenameSMIL ?? "", "dvrlocation": recording.dvrLocation ?? "", "token": token ?? "", "streamtype": "smil"]
        
        return self.manager.request(self.baseURL.appendingPathComponent("dvr/viewdvr"), method: .get, parameters: params).responseXMLDocument { r in
            if let videoString = r.result.value?.at_css("video")?["src"] {
                completionHandler(URL(string: videoString))
            }
            else {
                completionHandler(nil)
            }
        }
    }
    
    @discardableResult open func getSearchResults(_ term: String, completionHandler: @escaping ([TVProgram]?, Error?) -> Void) -> Request {
        let params = ["q_title": term, "token": token ?? ""]
        
        return self.manager.request(self.baseURL.appendingPathComponent("live/search"), method: .get, parameters: params).responseArray(keyPath: "results.programs.progs") {
            (response: DataResponse<[TVSearchProgram]>) in
            completionHandler(response.result.value, response.result.error)
        }
    }
    
}

extension String {
    
    public func unescape() -> String {
        var newString = self
        let char_dictionary = [
            "&amp;": "&",
            "&lt;": "<",
            "&gt;": ">",
            "&quot;": "\"",
            "&apos;": "'"
        ]
        for (escaped_char, unescaped_char) in char_dictionary {
            newString = newString.replacingOccurrences(of: escaped_char, with: unescaped_char, options: NSString.CompareOptions.regularExpression, range: nil)
        }
        return newString
    }
    
    public func cleanConnectorID() -> String {
        var result = self
        
        result = result.substring(to: result.characters.index(result.startIndex, offsetBy: 10))
        result = result.replacingOccurrences(of: "EP", with: "SH")
        
        return result
    }
}

extension DataRequest {
    public static func XMLResponseSerializer() -> DataResponseSerializer<XMLDocument> {
        return DataResponseSerializer { request, response, data, error in
            guard error == nil else { return .failure(error!) }
            
            guard let data = data, let XML = Kanna.XML(xml: data, encoding: String.Encoding.utf8) else {
                let errorDomain = "com.alamofireobjectmapper.error"
                let userInfo = [NSLocalizedFailureReasonErrorKey: "Data could not be serialized. Input data was nil."]
                return Result.failure(NSError(domain: errorDomain, code: 0, userInfo: userInfo))
            }
            
            return Result.success(XML)
        }
    }
    
    public static func HTMLResponseSerializer() -> DataResponseSerializer<XMLDocument> {
        return DataResponseSerializer { request, response, data, error in
            guard error == nil else { return .failure(error!) }
            
            guard let data = data, let HTML = Kanna.HTML(html: data, encoding: String.Encoding.utf8) else {
                let errorDomain = "com.alamofireobjectmapper.error"
                let userInfo = [NSLocalizedFailureReasonErrorKey: "Data could not be serialized. Input data was nil."]
                return Result.failure(NSError(domain: errorDomain, code: 0, userInfo: userInfo))
            }
            
            return Result.success(HTML)
        }
    }

     public func responseXMLDocument(_ completionHandler: @escaping (DataResponse<XMLDocument>) -> Void) -> Self {
        return response(responseSerializer: DataRequest.XMLResponseSerializer(), completionHandler: completionHandler)
    }
    
    public func responseHTMLDocument(_ completionHandler: @escaping (DataResponse<XMLDocument>) -> Void) -> Self {
        return response(responseSerializer: DataRequest.HTMLResponseSerializer(), completionHandler: completionHandler)
    }

}

