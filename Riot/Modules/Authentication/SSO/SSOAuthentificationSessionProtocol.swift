// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum SSOAuthentificationSessionError: Error {
    case userCanceled
}

/// A completion handler the session calls when it completes successfully, or when the user cancels the session.
public typealias SSOAuthenticationSessionCompletionHandler = (URL?, Error?) -> Void

/// An interface the session uses to ask a delegate for a presentation context.
protocol SSOAuthenticationSessionContextProviding {
    var window: UIWindow { get }
}

/// SSOAuthentificationSessionProtocol abstract a session that an app uses to authenticate a user through a web service (SFAuthenticationSession or ASWebAuthenticationSession).
protocol SSOAuthentificationSessionProtocol {
    
    /// Cancels the authentication session. Dismiss displayed authentication screen.
    func cancel()
    
    /// Provides context to target where in an application's UI the authorization view should be shown.
    func setContextProvider(_ contextProvider: SSOAuthenticationSessionContextProviding)
        
    /// Starts a web authentication session.
    /// - Parameters:
    ///   - url: A URL with the http or https scheme pointing to the authentication webpage.
    ///   - callbackURLScheme: The custom URL scheme that the app expects in the callback URL.
    ///   - completionHandler: A completion handler the session calls when it completes successfully, or when the user cancels the session.
    func authenticate(with url: URL, callbackURLScheme: String?, completionHandler: @escaping SSOAuthenticationSessionCompletionHandler)
}
