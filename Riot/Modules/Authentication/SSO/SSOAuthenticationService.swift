// 
// Copyright 2020 New Vector Ltd
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

enum SSOAuthenticationServiceError: Error {
    case tokenNotFound
    case userCanceled
    case unknown
}

@objcMembers
final class SSOAuthenticationService: NSObject {
    
    // MARK: - Constants
    
    // MARK: - Properties
    
    private let homeserverStringURL: String
        
    let callBackURLScheme: String?
    
    // MARK: - Setup
    
    init(homeserverStringURL: String) {
        self.homeserverStringURL = homeserverStringURL
        self.callBackURLScheme = BuildSettings.applicationURLScheme
        super.init()
    }
    
    // MARK: - Public
    
    func authenticationURL(for identityProvider: String?, transactionId: String) -> URL? {
        guard var authenticationComponent = URLComponents(string: self.homeserverStringURL) else {
            return nil
        }
        
        let ssoRedirectPath: String
        
        if let identityProvider = identityProvider {
            ssoRedirectPath = SSOURLConstants.Paths.unstableRedirect + identityProvider
        } else {
            ssoRedirectPath = SSOURLConstants.Paths.redirect
        }
        
        authenticationComponent.path = ssoRedirectPath
        
        var queryItems: [URLQueryItem] = []
        
        if let callBackURLScheme = self.buildCallBackURL(with: transactionId) {
            queryItems.append(URLQueryItem(name: SSOURLConstants.Parameters.redirectURL, value: callBackURLScheme))
        }
        
        authenticationComponent.queryItems = queryItems
        
        return authenticationComponent.url
    }
    
    func loginToken(from url: URL) -> String? {
        guard let components = URLComponents(string: url.absoluteString) else {
            return nil
        }
        return components.vc_getQueryItemValue(for: SSOURLConstants.Parameters.callbackLoginToken)
    }
    
    // MARK: - Private
    
    private func buildCallBackURL(with transactionId: String) -> String? {
        guard let callBackURLScheme = self.callBackURLScheme else {
            return nil
        }
        var urlComponents = URLComponents()
        urlComponents.scheme = callBackURLScheme
        urlComponents.host = CustomSchemeURLConstants.Hosts.connect
        
        // Transaction id is used to indentify the request
        urlComponents.queryItems = [URLQueryItem(name: CustomSchemeURLConstants.Parameters.transactionId, value: transactionId)]
        return urlComponents.string
    }
}
