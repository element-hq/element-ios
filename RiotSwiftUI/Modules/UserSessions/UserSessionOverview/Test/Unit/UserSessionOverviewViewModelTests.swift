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

import Combine
import XCTest

@testable import RiotSwiftUI

class UserSessionOverviewViewModelTests: XCTestCase {
    func test_whenVerifyCurrentSessionProcessed_completionWithVerifyCurrentSessionCalled() {
        let sessionInfo = createUserSessionInfo()
        let sut = UserSessionOverviewViewModel(sessionInfo: sessionInfo, service: MockUserSessionOverviewService(), settingsService: MockUserSessionSettings())
        
        XCTAssertEqual(sut.state.isPusherEnabled, nil)
        var modelResult: UserSessionOverviewViewModelResult?
        sut.completion = { result in
            modelResult = result
        }
        sut.process(viewAction: .verifySession)
        XCTAssertEqual(modelResult, .verifySession(sessionInfo))
    }
    
    func test_whenViewSessionDetailsProcessed_completionWithShowSessionDetailsCalled() {
        let sessionInfo = createUserSessionInfo()
        let sut = UserSessionOverviewViewModel(sessionInfo: sessionInfo, service: MockUserSessionOverviewService(), settingsService: MockUserSessionSettings())

        XCTAssertEqual(sut.state.isPusherEnabled, nil)
        var modelResult: UserSessionOverviewViewModelResult?
        sut.completion = { result in
            modelResult = result
        }
        sut.process(viewAction: .viewSessionDetails)
        XCTAssertEqual(modelResult, .showSessionDetails(sessionInfo: sessionInfo))
    }

    func test_whenViewSessionDetailsProcessed_toggleAvailablePusher() {
        let sessionInfo = createUserSessionInfo()
        let service = MockUserSessionOverviewService(pusherEnabled: true)
        let sut = UserSessionOverviewViewModel(sessionInfo: sessionInfo, service: service, settingsService: MockUserSessionSettings())

        XCTAssertTrue(sut.state.remotelyTogglingPushersAvailable)
        XCTAssertEqual(sut.state.isPusherEnabled, true)
        sut.process(viewAction: .togglePushNotifications)
        XCTAssertEqual(sut.state.isPusherEnabled, false)
        sut.process(viewAction: .togglePushNotifications)
        XCTAssertEqual(sut.state.isPusherEnabled, true)
    }
    
    func test_whenViewSessionDetailsProcessed_toggleNoPusher() {
        let sessionInfo = createUserSessionInfo()
        let service = MockUserSessionOverviewService(pusherEnabled: nil)
        let sut = UserSessionOverviewViewModel(sessionInfo: sessionInfo, service: service, settingsService: MockUserSessionSettings())

        XCTAssertTrue(sut.state.remotelyTogglingPushersAvailable)
        XCTAssertEqual(sut.state.isPusherEnabled, nil)
        sut.process(viewAction: .togglePushNotifications)
        XCTAssertEqual(sut.state.isPusherEnabled, nil)
        sut.process(viewAction: .togglePushNotifications)
        XCTAssertEqual(sut.state.isPusherEnabled, nil)
    }
    
    func test_whenViewSessionDetailsProcessed_remotelyTogglingPushersNotAvailable() {
        let sessionInfo = createUserSessionInfo()
        let service = MockUserSessionOverviewService(pusherEnabled: true, remotelyTogglingPushersAvailable: false)
        let sut = UserSessionOverviewViewModel(sessionInfo: sessionInfo, service: service, settingsService: MockUserSessionSettings())

        XCTAssertFalse(sut.state.remotelyTogglingPushersAvailable)
        XCTAssertEqual(sut.state.isPusherEnabled, true)
        sut.process(viewAction: .togglePushNotifications)
        XCTAssertEqual(sut.state.isPusherEnabled, true)
        sut.process(viewAction: .togglePushNotifications)
        XCTAssertEqual(sut.state.isPusherEnabled, true)
    }

    private func createUserSessionInfo() -> UserSessionInfo {
        UserSessionInfo(id: "session",
                        name: "iOS",
                        deviceType: .mobile,
                        verificationState: .unverified,
                        lastSeenIP: "10.0.0.10",
                        lastSeenTimestamp: Date().timeIntervalSince1970 - 100,
                        applicationName: "Element iOS",
                        applicationVersion: "1.9.7",
                        applicationURL: nil,
                        deviceModel: "iPhone XS",
                        deviceOS: "iOS 15.5",
                        lastSeenIPLocation: nil,
                        clientName: "Element",
                        clientVersion: "1.9.7",
                        isActive: true,
                        isCurrent: true)
    }
}
