//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@testable import Element

class UserInteractiveAuthenticationServiceTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    // MARK: - Tests
    
    func testGetFirstUncompletedStage() {
        
        let flow1 = MXLoginFlow()
        flow1.stages = ["example.type.foo", "example.type.bar"]
        
        let flow2 = MXLoginFlow()
        flow2.stages = ["example.type.foo", "example.type.baz"]
        
        let completedStages = ["example.type.foo"]
        
        let authenticationSession = MXAuthenticationSession()
        authenticationSession.completed = completedStages
        authenticationSession.flows = [flow1, flow2]

        let mxSession = MXSession()
        let authenticationSessionService = UserInteractiveAuthenticationService(session: mxSession)
    
        let firstUncompletedStage = authenticationSessionService.firstUncompletedFlowIdentifier(in: authenticationSession)
        
        XCTAssertNotNil(firstUncompletedStage)
        XCTAssertEqual(firstUncompletedStage, "example.type.bar")
    }
}
