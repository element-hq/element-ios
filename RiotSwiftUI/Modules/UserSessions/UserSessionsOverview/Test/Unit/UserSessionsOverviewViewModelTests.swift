//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import XCTest

@testable import RiotSwiftUI

class UserSessionsOverviewViewModelTests: XCTestCase {
    func testInitialStateEmpty() {
        let viewModel = UserSessionsOverviewViewModel(userSessionsOverviewService: MockUserSessionsOverviewService(),
                                                      settingsService: MockUserSessionSettings(),
                                                      showDeviceLogout: true)
        
        XCTAssertNil(viewModel.state.currentSessionViewData)
        XCTAssertTrue(viewModel.state.unverifiedSessionsViewData.isEmpty)
        XCTAssertTrue(viewModel.state.inactiveSessionsViewData.isEmpty)
        XCTAssertTrue(viewModel.state.otherSessionsViewData.isEmpty)
        XCTAssertFalse(viewModel.state.linkDeviceButtonVisible)
    }
    
    func testLoadOnDidAppear() {
        let viewModel = UserSessionsOverviewViewModel(userSessionsOverviewService: MockUserSessionsOverviewService(),
                                                      settingsService: MockUserSessionSettings(),
                                                      showDeviceLogout: true)
        viewModel.process(viewAction: .viewAppeared)
        
        XCTAssertNotNil(viewModel.state.currentSessionViewData)
        XCTAssertFalse(viewModel.state.unverifiedSessionsViewData.isEmpty)
        XCTAssertFalse(viewModel.state.inactiveSessionsViewData.isEmpty)
        XCTAssertFalse(viewModel.state.otherSessionsViewData.isEmpty)
        XCTAssertTrue(viewModel.state.linkDeviceButtonVisible)
    }
    
    func testSimpleActionProcessing() {
        let viewModel = UserSessionsOverviewViewModel(userSessionsOverviewService: MockUserSessionsOverviewService(),
                                                      settingsService: MockUserSessionSettings(),
                                                      showDeviceLogout: true)
        
        var result: UserSessionsOverviewViewModelResult?
        viewModel.completion = { action in
            result = action
        }
        
        viewModel.process(viewAction: .verifyCurrentSession)
        XCTAssertEqual(result, .verifyCurrentSession)
        
        result = nil
        viewModel.process(viewAction: .viewAllInactiveSessions)
        XCTAssertEqual(result, .showOtherSessions(sessionInfos: [], filter: .inactive))

        result = nil
        viewModel.process(viewAction: .viewAllOtherSessions)
        XCTAssertEqual(result, .showOtherSessions(sessionInfos: [], filter: .all))
        
        result = nil
        viewModel.process(viewAction: .linkDevice)
        XCTAssertEqual(result, .linkDevice)
    }
    
    func testShowSessionDetails() {
        let service = MockUserSessionsOverviewService()
        service.updateOverviewData { _ in }
        
        let viewModel = UserSessionsOverviewViewModel(userSessionsOverviewService: service,
                                                      settingsService: MockUserSessionSettings(),
                                                      showDeviceLogout: true)
        
        var result: UserSessionsOverviewViewModelResult?
        viewModel.completion = { action in
            result = action
        }
        
        guard let currentSession = service.currentSession else {
            XCTFail("The current session should be valid at this point")
            return
        }
        
        viewModel.process(viewAction: .viewCurrentSessionDetails)
        XCTAssertEqual(result, .showCurrentSessionOverview(sessionInfo: currentSession))
        
        guard let randomSession = service.otherSessions.randomElement() else {
            XCTFail("There should be other sessions")
            return
        }
        
        viewModel.process(viewAction: .tapUserSession(randomSession.id))
        XCTAssertEqual(result, .showUserSessionOverview(sessionInfo: randomSession))
    }
}
