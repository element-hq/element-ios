//
// Copyright 2021 New Vector Ltd
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
