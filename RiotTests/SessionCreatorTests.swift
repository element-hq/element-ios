// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest
@testable import Element

class SessionCreatorTests: XCTestCase {

    func testIdentityServer() async throws {
        let sessionCreator = SessionCreator(withAccountManager: .mock)

        let mockIS = "mock_identity_server"

        let credentials = MXCredentials(homeServer: "mock_home_server",
                                        userId: "@mock_user_id:localhost",
                                        accessToken: "mock_access_token")
        credentials.deviceId = "mock_device_id"
        let client = MXRestClient(credentials: credentials)
        client.identityServer = mockIS
        let session = await sessionCreator.createSession(credentials: credentials, client: client, removeOtherAccounts: false)
        
        XCTAssertEqual(credentials.identityServer, mockIS)
        XCTAssertEqual(session.credentials.identityServer, mockIS)
        XCTAssertEqual(session.identityService?.identityServer, mockIS)
    }

}

private extension MXKAccountManager {

    static var mock: MXKAccountManager {
        let result = MXKAccountManager.shared()
        result!.isSavingAccountsEnabled = false
        return result!
    }

}
