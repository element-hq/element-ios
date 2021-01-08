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
import SafariServices

/// LegacySSOAuthentificationSession is session used to authenticate a user through a web service on iOS 11 and earlier. It uses SFAuthenticationSession.
final class LegacySSOAuthentificationSession: SSOAuthentificationSessionProtocol {
        
    // MARK: - Constants

    // MARK: - Properties

    private var authentificationSession: SFAuthenticationSession?

    // MARK: - Public
    
    func setContextProvider(_ contextProvider: SSOAuthenticationSessionContextProviding) {
    }
    
    func authenticate(with url: URL, callbackURLScheme: String?, completionHandler: @escaping SSOAuthenticationSessionCompletionHandler) {
        
        let authentificationSession = SFAuthenticationSession(url: url, callbackURLScheme: callbackURLScheme) { (callbackURL, error) in
                        
            var finalError: Error?
            
            if let error = error as? SFAuthenticationError {
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
        authentificationSession.start()
    }

    func cancel() {
        self.authentificationSession?.cancel()
    }
}
