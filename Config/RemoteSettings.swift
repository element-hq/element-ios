// 
// Copyright 2021 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation
import MatrixKit
import MatrixSDK

/// BuildSettings provides settings from server.
@objcMembers
@objc class RemoteSettings: NSObject {
    ///Base URL used to get the settings from
    private static let baseUrl = "https://develop.element.io"
    /// Validity time (in s) of the settings cached locally (default 1 day)
    private static let timeToLive: TimeInterval = 24 * 3600
    /// Error domain used by RemoteSettings
    static let errorDomain = "RemoteSettingsErrorDomain"
    /// List of all possibile error codes
    enum errorCode: Int {
        case noHttpClient = 1
        case unknownRemoteError
    }
    
    enum cacheDataKey: String {
        case outboundGroupSessionKeyPreSharingStrategy = "outbound_group_session_key_pre_sharing_strategy"
    }
    private static let lastUpdateKey = "remote_settings_last_update_time"
    private static let cacheEntryKey = "remote_settings_cache"

    /// singleton
    static let shared = RemoteSettings()

    /// http client used to request the server
    private let httpClient: MXHTTPClient?
    /// Last time (since 1970) the cache has been update. 0 if the request has never been performed.
    private var lastUpdateTime: TimeInterval
    
    /// Base init
    private override init() {
        httpClient = MXHTTPClient(baseURL: RemoteSettings.baseUrl, andOnUnrecognizedCertificateBlock: nil)
        lastUpdateTime = UserDefaults.standard.double(forKey: RemoteSettings.lastUpdateKey)
        super.init()
    }
    
    /**
     Requests config file from server and update the cache
     
     @param success called after success of the request and the cache has been updated
     @param failure called if an internal or request error occurs
     */
    func request(success: (() -> Void)?, failure: ((Error) -> Void)?) {
        guard !isCacheValid() else {
            success?()
            return
        }
        
        guard let httpClient = self.httpClient else {
            failure?(NSError(domain: RemoteSettings.errorDomain, code: errorCode.noHttpClient.rawValue, userInfo: [NSLocalizedDescriptionKey : "Cannot instantiate httpClient"]))
            return
        }
        
        httpClient.request(withMethod: "GET", path: "config.json", parameters: [:]) { (response) in
            UserDefaults.standard.setValue(response, forKey: RemoteSettings.cacheEntryKey)
            self.storeUpdateTime()
            success?()
        } failure: { (error) in
            failure?(error ?? NSError(domain: RemoteSettings.errorDomain, code: errorCode.unknownRemoteError.rawValue, userInfo: [NSLocalizedDescriptionKey : "Unkown remote error"]))
        }
    }
    
    subscript(key: cacheDataKey!) -> String? {
        return cachedData()?[key.rawValue] as? String
    }
    
    subscript(key: cacheDataKey!) -> Int? {
        return cachedData()?[key.rawValue] as? Int
    }
    
    subscript(key: cacheDataKey!) -> UInt? {
        return cachedData()?[key.rawValue] as? UInt
    }
    
    subscript(key: cacheDataKey!) -> MXKKeyPreSharingStrategy? {
        let value: UInt? = self[key]
        if let value = value {
            return MXKKeyPreSharingStrategy(rawValue: value)
        }
        return nil
    }
    
    private func cachedData() -> [String : Any]? {
        return UserDefaults.standard.dictionary(forKey: RemoteSettings.cacheEntryKey)
    }
    
    private func isCacheValid() -> Bool {
        return lastUpdateTime > 0 && Date().timeIntervalSince1970 - lastUpdateTime < RemoteSettings.timeToLive
    }
    
    private func storeUpdateTime() {
        lastUpdateTime = Date().timeIntervalSince1970
        UserDefaults.standard.set(lastUpdateTime, forKey: RemoteSettings.lastUpdateKey)
    }
}
