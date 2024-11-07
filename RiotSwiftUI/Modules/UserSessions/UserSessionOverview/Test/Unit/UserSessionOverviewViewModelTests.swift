//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
