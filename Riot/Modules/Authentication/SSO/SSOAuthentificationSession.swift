//
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
