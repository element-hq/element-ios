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

import XCTest
@testable import Element

class SessionCreatorTests: XCTestCase {

    func testIdentityServer() async throws {
        let sessionCreator = SessionCreator(withAccountManager: .mock)

        let mockIS = "mock_identity_server"

        let credentials = MXCredentials(homeServer: "mock_home_server",
                                        userId: "mock_user_id",
                                        accessToken: "mock_access_token")
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
