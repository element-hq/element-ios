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
    
    private enum SSOURLPath {
        static let redirect = "/_matrix/client/r0/login/sso/redirect"
        static let unstableRedirect = "/_matrix/client/unstable/org.matrix.msc2858/login/sso/redirect/"
    }
    
    private enum SSOURLParameters {
        static let callbackLoginToken = "loginToken"
        static let redirectURL = "redirectUrl"
    }
    
    // TODO: Move this constant
    private enum ApplicationSchemePathes {
        static let connect = "connect"
    }
    
    // MARK: - Properties
    
    private let homeserverStringURL: String
        
    lazy var callBackURLScheme: String? = {
        return self.buildCallBackURLScheme()
    }()
    
    // MARK: - Setup
    
    init(homeserverStringURL: String) {
        self.homeserverStringURL = homeserverStringURL        
        super.init()
    }
    
    // MARK: - Public
    
    func authenticationURL(for identityProvider: String?) -> URL? {                
        guard var authenticationComponent = URLComponents(string: self.homeserverStringURL) else {
            return nil
        }
        
        let ssoRedirectPath: String
        
        if let identityProvider = identityProvider {
            ssoRedirectPath = SSOURLPath.unstableRedirect + identityProvider
        } else {
            ssoRedirectPath = SSOURLPath.redirect
        }
        
        authenticationComponent.path = ssoRedirectPath
        
        var queryItems: [URLQueryItem] = []
        
        if let callBackURLScheme = self.callBackURLScheme {
            queryItems.append(URLQueryItem(name: SSOURLParameters.redirectURL, value: callBackURLScheme))
        }
        
        authenticationComponent.queryItems = queryItems
        
        return authenticationComponent.url
    }
    
    func loginToken(from url: URL) -> String? {
        guard let components = URLComponents(string: url.absoluteString) else {
            return nil
        }
        let tokenQueryItem = components.queryItems?.first(where: { $0.name == SSOURLParameters.callbackLoginToken })
        return tokenQueryItem?.value
    }
    
    // MARK: - Private
    
    private func buildCallBackURLScheme() -> String? {
        guard let appScheme = BuildSettings.applicationURLScheme else {
            return nil
        }
        var urlComponents = URLComponents()
        urlComponents.scheme = appScheme
        urlComponents.host = ApplicationSchemePathes.connect        
        return urlComponents.string
    }
}
