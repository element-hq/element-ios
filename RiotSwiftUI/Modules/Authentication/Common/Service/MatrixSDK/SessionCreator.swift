//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
            let otherAccounts = accountManager.accounts.filter { $0.mxCredentials.userId != credentials.userId }
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
