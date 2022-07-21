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
import AuthenticationServices

/// Provides context to target where in an application's UI the authorization view should be shown.
class SSOAuthenticationSessionContextProvider: NSObject, SSOAuthenticationSessionContextProviding, ASWebAuthenticationPresentationContextProviding {
    let window: UIWindow
    
    init(window: UIWindow) {
        self.window = window
    }
    
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return window
    }
}

/// SSOAuthentificationSession is session used to authenticate a user through a web service on iOS 12+. It uses ASWebAuthenticationSession.
/// More information: https://developer.apple.com/documentation/authenticationservices/authenticating_a_user_through_a_web_service
final class SSOAuthentificationSession: SSOAuthentificationSessionProtocol {
    
    // MARK: - Constants

    // MARK: - Properties

    private var authentificationSession: ASWebAuthenticationSession?
    private var contextProvider: SSOAuthenticationSessionContextProviding?

    // MARK: - Public
    
    func setContextProvider(_ contextProvider: SSOAuthenticationSessionContextProviding) {
        self.contextProvider = contextProvider
    }
    
    func authenticate(with url: URL, callbackURLScheme: String?, completionHandler: @escaping SSOAuthenticationSessionCompletionHandler) {
        
        let authentificationSession = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackURLScheme) { (callbackURL, error) in
                        
            var finalError: Error?
            
            if let error = error as? ASWebAuthenticationSessionError {
                switch error.code {
                case .canceledLogin:
                    finalError = SSOAuthentificationSessionError.userCanceled
                default:
                    finalError = error
                }
            }
            
            completionHandler(callbackURL, finalError)
        }
        
        self.authentificationSession = authentificationSession
        
        if let asWebContextProvider = contextProvider as? ASWebAuthenticationPresentationContextProviding {
            authentificationSession.presentationContextProvider = asWebContextProvider
        }
        
        authentificationSession.start()
    }

    func cancel() {
        self.authentificationSession?.cancel()
    }
}
