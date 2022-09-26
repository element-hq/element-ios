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
import Combine

@testable import RiotSwiftUI

class UserSessionOverviewViewModelTests: XCTestCase {

    var sut: UserSessionOverviewViewModel!

    func test_whenVerifyCurrentSessionProcessed_completionWithVerifyCurrentSessionCalled() {
        sut = UserSessionOverviewViewModel(userSessionInfo: createUserSessionInfo(), isCurrentSession: true)
        
        var modelResult: UserSessionOverviewViewModelResult?
        sut.completion = { result in
            modelResult = result
        }
        sut.process(viewAction: .verifyCurrentSession)
        XCTAssertEqual(modelResult, .verifyCurrentSession)
    }
    
    func test_whenViewSessionDetailsProcessed_completionWithShowSessionDetailsCalled() {
        let session = createUserSessionInfo()
        sut = UserSessionOverviewViewModel(userSessionInfo: session, isCurrentSession: true)

        var modelResult: UserSessionOverviewViewModelResult?
        sut.completion = { result in
            modelResult = result
        }
        sut.process(viewAction: .viewSessionDetails)
        XCTAssertEqual(modelResult, .showSessionDetails(sessionInfo: session))
    }
    
    private func createUserSessionInfo() -> UserSessionInfo {
        UserSessionInfo(sessionId: "session",
                               sessionName: "iOS",
                               deviceType: .mobile,
                               isVerified: false,
                               lastSeenIP: "10.0.0.10",
                               lastSeenTimestamp: Date().timeIntervalSince1970 - 100)
    }
}
