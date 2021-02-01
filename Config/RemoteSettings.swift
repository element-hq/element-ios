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
import MatrixSDK

@objcMembers
@objc class RemoteSettings: NSObject {
    
    static let errorDomain = "RemoteSettingsErrorDomain"
    
    enum errorCode: Int {
        case noHttpClient = 1
        case unknownRemoteError
    }
    
    static let shared = RemoteSettings()

    private let httpClient: MXHTTPClient?
    
    private override init() {
        httpClient = MXHTTPClient(baseURL: "https://develop.element.io", andOnUnrecognizedCertificateBlock: nil)
        super.init()
    }
    
    func request(success: (() -> Void)?, failure: ((Error) -> Void)?) {
        guard let httpClient = self.httpClient else {
            failure?(NSError(domain: RemoteSettings.errorDomain, code: errorCode.noHttpClient.rawValue, userInfo: [NSLocalizedDescriptionKey : "Cannot instantiate httpClient"]))
            return
        }
        
        httpClient.request(withMethod: "GET", path: "config.json", parameters: [:]) { (response) in
//            UserDefaults.standard.setValue(response, forKey: "Remote")
            response?.forEach({ (key, value) in
                guard let key = key as? String else {
                    return
                }
                UserDefaults.standard.setValue(value, forKey: key)
            })
            success?()
        } failure: { (error) in
            failure?(error ?? NSError(domain: RemoteSettings.errorDomain, code: errorCode.unknownRemoteError.rawValue, userInfo: [NSLocalizedDescriptionKey : "Unkown remote error"]))
        }
    }
    
//    subscript(key: String!) -> Any? {
//        return (UserDefaults.standard.object(forKey: "Remote") as? [AnyHashable : Any])?[key]
//    }
}
