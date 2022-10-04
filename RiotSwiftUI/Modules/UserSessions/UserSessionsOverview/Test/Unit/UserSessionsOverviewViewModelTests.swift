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

import Combine
import XCTest

@testable import RiotSwiftUI

class UserSessionsOverviewViewModelTests: XCTestCase {
    func testInitialStateEmpty() {
        let viewModel = UserSessionsOverviewViewModel(userSessionsOverviewService: MockUserSessionsOverviewService())
        
        XCTAssertNil(viewModel.state.currentSessionViewData)
        XCTAssertTrue(viewModel.state.unverifiedSessionsViewData.isEmpty)
        XCTAssertTrue(viewModel.state.inactiveSessionsViewData.isEmpty)
        XCTAssertTrue(viewModel.state.otherSessionsViewData.isEmpty)
    }
    
    func testLoadOnDidAppear() {
        let viewModel = UserSessionsOverviewViewModel(userSessionsOverviewService: MockUserSessionsOverviewService())
        viewModel.process(viewAction: .viewAppeared)
        
        XCTAssertNotNil(viewModel.state.currentSessionViewData)
        XCTAssertFalse(viewModel.state.unverifiedSessionsViewData.isEmpty)
        XCTAssertFalse(viewModel.state.inactiveSessionsViewData.isEmpty)
        XCTAssertFalse(viewModel.state.otherSessionsViewData.isEmpty)
    }
    
    func testSimpleActionProcessing() {
        let viewModel = UserSessionsOverviewViewModel(userSessionsOverviewService: MockUserSessionsOverviewService())
        
        var result: UserSessionsOverviewViewModelResult?
        viewModel.completion = { action in
            result = action
        }
        
        viewModel.process(viewAction: .verifyCurrentSession)
        XCTAssertEqual(result, .verifyCurrentSession)
        
        viewModel.process(viewAction: .viewAllInactiveSessions)
        XCTAssertEqual(result, .showOtherSessions(sessionsInfo: [], filter: .inactive))
    }
    
    func testShowSessionDetails() {
        let service = MockUserSessionsOverviewService()
        service.updateOverviewData { _ in }
        
        let viewModel = UserSessionsOverviewViewModel(userSessionsOverviewService: service)
        
        var result: UserSessionsOverviewViewModelResult?
        viewModel.completion = { action in
            result = action
        }
        
        guard let currentSession = service.overviewData.currentSession else {
            XCTFail("The current session should be valid at this point")
            return
        }
        
        viewModel.process(viewAction: .viewCurrentSessionDetails)
        XCTAssertEqual(result, .showCurrentSessionOverview(sessionInfo: currentSession))
        
        guard let randomSession = service.overviewData.otherSessions.randomElement() else {
            XCTFail("There should be other sessions")
            return
        }
        
        viewModel.process(viewAction: .tapUserSession(randomSession.id))
        XCTAssertEqual(result, .showUserSessionOverview(sessionInfo: randomSession))
    }
}
