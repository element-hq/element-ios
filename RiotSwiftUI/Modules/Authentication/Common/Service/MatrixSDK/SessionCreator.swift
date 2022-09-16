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

protocol SessionCreatorProtocol {
    /// Creates an `MXSession` using the supplied credentials and REST client.
    /// - Parameters:
    ///   - credentials: The `MXCredentials` for the account.
    ///   - client: The client that completed the authentication.
    ///   - removeOtherAccounts: Flag to remove other accounts than the account specified with the `credentials.userId`.
    /// - Returns: A new `MXSession` for the account.
    @MainActor
    func createSession(credentials: MXCredentials, client: AuthenticationRestClient, removeOtherAccounts: Bool) -> MXSession
}

/// A struct that provides common functionality to create a new session.
struct SessionCreator: SessionCreatorProtocol {

    private let accountManager: MXKAccountManager

    init(withAccountManager accountManager: MXKAccountManager = .shared()) {
        self.accountManager = accountManager
    }

    @MainActor
    func createSession(credentials: MXCredentials, client: AuthenticationRestClient, removeOtherAccounts: Bool) -> MXSession {
        // Use identity server provided in the client
        if credentials.identityServer == nil {
            credentials.identityServer = client.identityServer
        }

        if removeOtherAccounts {
            let otherAccounts = accountManager.accounts.filter({ $0.mxCredentials.userId != credentials.userId })
            for account in otherAccounts {
                accountManager.removeAccount(account, completion: nil)
            }
        }

        if let account = accountManager.account(forUserId: credentials.userId) {
            accountManager.hydrateAccount(account, with: credentials)
            return account.mxSession
        } else {
            let account = MXKAccount(credentials: credentials)

            //  set identity server of the new account
            if let identityServer = credentials.identityServer {
                account.identityServerURL = identityServer
            }

            accountManager.addAccount(account, andOpenSession: true)
            return account.mxSession
        }
    }
}
