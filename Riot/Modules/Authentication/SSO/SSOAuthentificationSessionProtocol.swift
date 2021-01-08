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
