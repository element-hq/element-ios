// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

@testable import Element

struct MockSessionCreator: SessionCreatorProtocol {
    /// Returns a basic session created from the supplied credentials. This prevents the app from setting up the account during tests.
    @MainActor
    func createSession(credentials: MXCredentials, client: AuthenticationRestClient, removeOtherAccounts: Bool) -> MXSession {
        let client = MXRestClient(credentials: credentials,
                                  unauthenticatedHandler: { _,_,_,_ in }) // The handler is expected if credentials are set.
        return MXSession(matrixRestClient: client)
    }
}
