// 
// Copyright 2022 New Vector Ltd
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

/// A WIP class that has common functionality to create a new session.
class SessionCreator {
    /// Creates an `MXSession` using the supplied credentials and REST client.
    func createSession(credentials: MXCredentials, client: MXRestClient) -> MXSession {
        // Report the new account in account manager
        if credentials.identityServer == nil {
            #warning("Check that the client is actually updated with this info?")
            credentials.identityServer = client.identityServer
        }
        
        let account = MXKAccount(credentials: credentials)
        
        if let identityServer = credentials.identityServer {
            account.identityServerURL = identityServer
        }
        
        MXKAccountManager.shared().addAccount(account, andOpenSession: true)
        return account.mxSession
    }
}
