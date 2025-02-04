//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@testable import RiotSwiftUI

class UserOtherSessionsViewModelTests: XCTestCase {
    private let unverifiedSectionHeader = UserOtherSessionsHeaderViewData(title: VectorL10n.userSessionUnverifiedShort,
                                                                          subtitle: VectorL10n.userOtherSessionUnverifiedSessionsHeaderSubtitle + " %@",
                                                                          iconName: Asset.Images.userOtherSessionsUnverified.name)
    
    private let inactiveSectionHeader = UserOtherSessionsHeaderViewData(title: VectorL10n.userOtherSessionFilterMenuInactive,
                                                                        subtitle: VectorL10n.userSessionsOverviewSecurityRecommendationsInactiveInfo + " %@",
                                                                        iconName: Asset.Images.userOtherSessionsInactive.name)
    
    private let allSectionHeader = UserOtherSessionsHeaderViewData(title: nil,
                                                                   subtitle: VectorL10n.userSessionsOverviewOtherSessionsSectionInfo,
                                                                   iconName: nil)
    
    private let verifiedSectionHeader = UserOtherSessionsHeaderViewData(title: VectorL10n.userOtherSessionFilterMenuVerified,
                                                                        subtitle: VectorL10n.userOtherSessionVerifiedSessionsHeaderSubtitle + " %@",
                                                                        iconName: Asset.Images.userOtherSessionsVerified.name)
    
    func test_whenUserOtherSessionSelectedProcessed_completionWithShowUserSessionOverviewCalled() {
        let expectedUserSessionInfo = createUserSessionInfo(sessionId: "session 2")
        let sessionInfos = [createUserSessionInfo(sessionId: "session 1"),
                            expectedUserSessionInfo]
        let sut = createSUT(sessionInfos: sessionInfos, filter: .inactive)
        
        var modelResult: UserOtherSessionsViewModelResult?
        sut.completion = { result in
            modelResult = result
        }
        sut.process(viewAction: .userOtherSessionSelected(sessionId: expectedUserSessionInfo.id))
        XCTAssertEqual(modelResult, .showUserSessionOverview(sessionInfo: expectedUserSessionInfo))
    }
    
    func test_whenModelCreated_withInactiveFilter_viewStateIsCorrect() {
        let sessionInfos = [createUserSessionInfo(sessionId: "session 1", isActive: false),
                            createUserSessionInfo(sessionId: "session 2", isActive: false)]
        let sut = createSUT(sessionInfos: sessionInfos, filter: .inactive)
        
        let expectedItems = sessionInfos.filter { !$0.isActive }.asViewData()
        let bindings = UserOtherSessionsBindings(filter: .inactive, isEditModeEnabled: false)
        let expectedState = UserOtherSessionsViewState(bindings: bindings,
                                                       title: "Title",
                                                       sessionItems: expectedItems,
                                                       header: inactiveSectionHeader,
                                                       emptyItemsTitle: VectorL10n.userOtherSessionNoInactiveSessions,
                                                       allItemsSelected: false,
                                                       enableSignOutButton: false,
                                                       showLocationInfo: false,
                                                       showDeviceLogout: true)
        XCTAssertEqual(sut.state, expectedState)
    }
    
    func test_whenModelCreated_withAllFilter_viewStateIsCorrect() {
        let sessionInfos = [createUserSessionInfo(sessionId: "session 1"),
                            createUserSessionInfo(sessionId: "session 2")]
        let sut = createSUT(sessionInfos: sessionInfos, filter: .all)
        
        let expectedItems = sessionInfos.filter { !$0.isCurrent }.asViewData()
        let bindings = UserOtherSessionsBindings(filter: .all, isEditModeEnabled: false)
        let expectedState = UserOtherSessionsViewState(bindings: bindings,
                                                       title: "Title",
                                                       sessionItems: expectedItems,
                                                       header: allSectionHeader,
                                                       emptyItemsTitle: "",
                                                       allItemsSelected: false,
                                                       enableSignOutButton: false,
                                                       showLocationInfo: false,
                                                       showDeviceLogout: true)
        XCTAssertEqual(sut.state, expectedState)
    }
    
    func test_whenModelCreated_withUnverifiedFilter_viewStateIsCorrect() {
        let sessionInfos = [createUserSessionInfo(sessionId: "session 1"),
                            createUserSessionInfo(sessionId: "session 2", verificationState: .permanentlyUnverified),
                            createUserSessionInfo(sessionId: "session 3", verificationState: .unknown)]
        let sut = createSUT(sessionInfos: sessionInfos, filter: .unverified)
        
        let expectedItems = sessionInfos
            .filter {
                !$0.isCurrent && $0.verificationState.isUnverified
            }
            .asViewData()
        let bindings = UserOtherSessionsBindings(filter: .unverified, isEditModeEnabled: false)
        let expectedState = UserOtherSessionsViewState(bindings: bindings,
                                                       title: "Title",
                                                       sessionItems: expectedItems,
                                                       header: unverifiedSectionHeader,
                                                       emptyItemsTitle: VectorL10n.userOtherSessionNoUnverifiedSessions,
                                                       allItemsSelected: false,
                                                       enableSignOutButton: false,
                                                       showLocationInfo: false,
                                                       showDeviceLogout: true)
        XCTAssertEqual(expectedItems.count, 2)
        XCTAssertEqual(sut.state, expectedState)
    }
    
    func test_whenModelCreated_withVerifiedFilter_viewStateIsCorrect() {
        let sessionInfos = [createUserSessionInfo(sessionId: "session 1", verificationState: .verified),
                            createUserSessionInfo(sessionId: "session 2", verificationState: .verified)]
        let sut = createSUT(sessionInfos: sessionInfos, filter: .verified)
        
        let expectedItems = sessionInfos.filter { !$0.isCurrent }.asViewData()
        let bindings = UserOtherSessionsBindings(filter: .verified, isEditModeEnabled: false)
        let expectedState = UserOtherSessionsViewState(bindings: bindings,
                                                       title: "Title",
                                                       sessionItems: expectedItems,
                                                       header: verifiedSectionHeader,
                                                       emptyItemsTitle: VectorL10n.userOtherSessionNoVerifiedSessions,
                                                       allItemsSelected: false,
                                                       enableSignOutButton: false,
                                                       showLocationInfo: false,
                                                       showDeviceLogout: true)
        XCTAssertEqual(sut.state, expectedState)
    }
    
    func test_whenModelCreated_withVerifiedFilterWithNoVerifiedSessions_viewStateIsCorrect() {
        let sessionInfos = [createUserSessionInfo(sessionId: "session 1"),
                            createUserSessionInfo(sessionId: "session 2")]
        let sut = createSUT(sessionInfos: sessionInfos, filter: .verified)
        let bindings = UserOtherSessionsBindings(filter: .verified, isEditModeEnabled: false)
        let expectedState = UserOtherSessionsViewState(bindings: bindings,
                                                       title: "Title",
                                                       sessionItems: [],
                                                       header: verifiedSectionHeader,
                                                       emptyItemsTitle: VectorL10n.userOtherSessionNoVerifiedSessions,
                                                       allItemsSelected: false,
                                                       enableSignOutButton: false,
                                                       showLocationInfo: false,
                                                       showDeviceLogout: true)
        XCTAssertEqual(sut.state, expectedState)
    }
    
    func test_whenModelCreated_withUnverifiedFilterWithNoUnverifiedSessions_viewStateIsCorrect() {
        let sessionInfos = [createUserSessionInfo(sessionId: "session 1", verificationState: .verified),
                            createUserSessionInfo(sessionId: "session 2", verificationState: .verified)]
        let sut = createSUT(sessionInfos: sessionInfos, filter: .unverified)
        let bindings = UserOtherSessionsBindings(filter: .unverified, isEditModeEnabled: false)
        let expectedState = UserOtherSessionsViewState(bindings: bindings,
                                                       title: "Title",
                                                       sessionItems: [],
                                                       header: unverifiedSectionHeader,
                                                       emptyItemsTitle: VectorL10n.userOtherSessionNoUnverifiedSessions,
                                                       allItemsSelected: false,
                                                       enableSignOutButton: false,
                                                       showLocationInfo: false,
                                                       showDeviceLogout: true)
        XCTAssertEqual(sut.state, expectedState)
    }
    
    func test_whenModelCreated_withInactiveFilterWithNoInactiveSessions_viewStateIsCorrect() {
        let sessionInfos = [createUserSessionInfo(sessionId: "session 1", isActive: true),
                            createUserSessionInfo(sessionId: "session 2", isActive: true)]
        let sut = createSUT(sessionInfos: sessionInfos, filter: .inactive)
        let bindings = UserOtherSessionsBindings(filter: .inactive, isEditModeEnabled: false)
        let expectedState = UserOtherSessionsViewState(bindings: bindings,
                                                       title: "Title",
                                                       sessionItems: [],
                                                       header: inactiveSectionHeader,
                                                       emptyItemsTitle: VectorL10n.userOtherSessionNoInactiveSessions,
                                                       allItemsSelected: false,
                                                       enableSignOutButton: false,
                                                       showLocationInfo: false,
                                                       showDeviceLogout: true)
        XCTAssertEqual(sut.state, expectedState)
    }
    
    func test_whenEditModeEnabledAndAllItemsSelected_viewStateIsCorrect() {
        let sessionInfos = [createUserSessionInfo(sessionId: "session 1"),
                            createUserSessionInfo(sessionId: "session 2")]
        let sut = createSUT(sessionInfos: sessionInfos, filter: .all)
        toggleEditMode(for: sut, value: true)
        sut.process(viewAction: .userOtherSessionSelected(sessionId: "session 1"))
        sut.process(viewAction: .userOtherSessionSelected(sessionId: "session 2"))
        
        let expectedItems = sessionInfos.map { UserSessionListItemViewDataFactory().create(from: $0, isSelected: true) }
        let bindings = UserOtherSessionsBindings(filter: .all, isEditModeEnabled: true)
        let expectedState = UserOtherSessionsViewState(bindings: bindings,
                                                       title: VectorL10n.userOtherSessionSelectedCount("2"),
                                                       sessionItems: expectedItems,
                                                       header: allSectionHeader,
                                                       emptyItemsTitle: "",
                                                       allItemsSelected: true,
                                                       enableSignOutButton: true,
                                                       showLocationInfo: false,
                                                       showDeviceLogout: true)
        XCTAssertEqual(sut.state, expectedState)
    }
    
    func test_whenEditModeEnabledAndItemSelectedAndDeselected_viewStateIsCorrect() {
        let sessionInfos = [createUserSessionInfo(sessionId: "session 1"),
                            createUserSessionInfo(sessionId: "session 2")]
        let sut = createSUT(sessionInfos: sessionInfos, filter: .all)
        toggleEditMode(for: sut, value: true)
        sut.process(viewAction: .userOtherSessionSelected(sessionId: "session 1"))
        sut.process(viewAction: .userOtherSessionSelected(sessionId: "session 1"))
        
        let expectedItems = sessionInfos.map { UserSessionListItemViewDataFactory().create(from: $0, isSelected: false) }
        let bindings = UserOtherSessionsBindings(filter: .all, isEditModeEnabled: true)
        let expectedState = UserOtherSessionsViewState(bindings: bindings,
                                                       title: VectorL10n.userOtherSessionSelectedCount("0"),
                                                       sessionItems: expectedItems,
                                                       header: allSectionHeader,
                                                       emptyItemsTitle: "",
                                                       allItemsSelected: false,
                                                       enableSignOutButton: false,
                                                       showLocationInfo: false,
                                                       showDeviceLogout: true)
        XCTAssertEqual(sut.state, expectedState)
    }
    
    func test_whenEditModeEnabledAndNotAllItemsSelected_viewStateIsCorrect() {
        let sessionInfos = [createUserSessionInfo(sessionId: "session 1"),
                            createUserSessionInfo(sessionId: "session 2")]
        let sut = createSUT(sessionInfos: sessionInfos, filter: .all)
        toggleEditMode(for: sut, value: true)
        sut.process(viewAction: .userOtherSessionSelected(sessionId: "session 2"))
        
        let expectedItems = sessionInfos.map { UserSessionListItemViewDataFactory().create(from: $0, isSelected: $0.id == "session 2") }
        let bindings = UserOtherSessionsBindings(filter: .all, isEditModeEnabled: true)
        let expectedState = UserOtherSessionsViewState(bindings: bindings,
                                                       title: VectorL10n.userOtherSessionSelectedCount("1"),
                                                       sessionItems: expectedItems,
                                                       header: allSectionHeader,
                                                       emptyItemsTitle: "",
                                                       allItemsSelected: false,
                                                       enableSignOutButton: true,
                                                       showLocationInfo: false,
                                                       showDeviceLogout: true)
        XCTAssertEqual(sut.state, expectedState)
    }
    
    func test_whenEditModeEnabledAndAllItemsSelectedByButton_viewStateIsCorrect() {
        let sessionInfos = [createUserSessionInfo(sessionId: "session 1"),
                            createUserSessionInfo(sessionId: "session 2")]
        let sut = createSUT(sessionInfos: sessionInfos, filter: .all)
        toggleEditMode(for: sut, value: true)
        sut.process(viewAction: .toggleAllSelection)
        
        let expectedItems = sessionInfos.map { UserSessionListItemViewDataFactory().create(from: $0, isSelected: true) }
        let bindings = UserOtherSessionsBindings(filter: .all, isEditModeEnabled: true)
        let expectedState = UserOtherSessionsViewState(bindings: bindings,
                                                       title: VectorL10n.userOtherSessionSelectedCount("2"),
                                                       sessionItems: expectedItems,
                                                       header: allSectionHeader,
                                                       emptyItemsTitle: "",
                                                       allItemsSelected: true,
                                                       enableSignOutButton: true,
                                                       showLocationInfo: false,
                                                       showDeviceLogout: true)
        XCTAssertEqual(sut.state, expectedState)
    }
    
    func test_whenEditModeEnabledAndAllItemsDeselectedByButton_viewStateIsCorrect() {
        let sessionInfos = [createUserSessionInfo(sessionId: "session 1"),
                            createUserSessionInfo(sessionId: "session 2")]
        let sut = createSUT(sessionInfos: sessionInfos, filter: .all)
        toggleEditMode(for: sut, value: true)
        sut.process(viewAction: .toggleAllSelection)
        sut.process(viewAction: .toggleAllSelection)
        let expectedItems = sessionInfos.map { UserSessionListItemViewDataFactory().create(from: $0, isSelected: false) }
        let bindings = UserOtherSessionsBindings(filter: .all, isEditModeEnabled: true)
        let expectedState = UserOtherSessionsViewState(bindings: bindings,
                                                       title: VectorL10n.userOtherSessionSelectedCount("0"),
                                                       sessionItems: expectedItems,
                                                       header: allSectionHeader,
                                                       emptyItemsTitle: "",
                                                       allItemsSelected: false,
                                                       enableSignOutButton: false,
                                                       showLocationInfo: false,
                                                       showDeviceLogout: true)
        XCTAssertEqual(sut.state, expectedState)
    }
    
    func test_whenEditModeEnabledDisabledAndEnabled_viewStateIsCorrect() {
        let sessionInfos = [createUserSessionInfo(sessionId: "session 1"),
                            createUserSessionInfo(sessionId: "session 2")]
        let sut = createSUT(sessionInfos: sessionInfos, filter: .all)
        toggleEditMode(for: sut, value: true)
        sut.process(viewAction: .editModeWasToggled)
        sut.process(viewAction: .userOtherSessionSelected(sessionId: "session 1"))
        sut.process(viewAction: .userOtherSessionSelected(sessionId: "session 2"))
        toggleEditMode(for: sut, value: false)
        toggleEditMode(for: sut, value: true)
        let expectedItems = sessionInfos.map { UserSessionListItemViewDataFactory().create(from: $0, isSelected: false) }
        let bindings = UserOtherSessionsBindings(filter: .all, isEditModeEnabled: true)
        let expectedState = UserOtherSessionsViewState(bindings: bindings,
                                                       title: VectorL10n.userOtherSessionSelectedCount("0"),
                                                       sessionItems: expectedItems,
                                                       header: allSectionHeader,
                                                       emptyItemsTitle: "",
                                                       allItemsSelected: false,
                                                       enableSignOutButton: false,
                                                       showLocationInfo: false,
                                                       showDeviceLogout: true)
        XCTAssertEqual(sut.state, expectedState)
    }
    
    func test_whenSignOutAllUserSessions_correctCompletionResultReceived() {
        let sessionInfoWithSessionId1 = createUserSessionInfo(sessionId: "session 1")
        let sessionInfoWithSessionId3 = createUserSessionInfo(sessionId: "session 3")
        let sessionInfos = [sessionInfoWithSessionId1,
                            createUserSessionInfo(sessionId: "session 2"),
                            sessionInfoWithSessionId3]
        let sut = createSUT(sessionInfos: sessionInfos, filter: .all)
        var receivedUserSessions = [UserSessionInfo]()
        sut.completion = { result in
            switch result {
            case let .logoutFromUserSessions(sessionInfos: sessionInfos):
                receivedUserSessions = sessionInfos
            default:
                break
            }
        }
        toggleEditMode(for: sut, value: true)
        sut.process(viewAction: .userOtherSessionSelected(sessionId: sessionInfoWithSessionId1.id))
        sut.process(viewAction: .userOtherSessionSelected(sessionId: sessionInfoWithSessionId3.id))
        sut.process(viewAction: .logoutSelectedUserSessions)
        XCTAssertEqual(receivedUserSessions, [sessionInfoWithSessionId1, sessionInfoWithSessionId3])
    }
    
    func test_whenSignOutSelectedUserSessions_correctCompletionResultReceived() {
        let sessionInfos = [createUserSessionInfo(sessionId: "session 1"),
                            createUserSessionInfo(sessionId: "session 2"),
                            createUserSessionInfo(sessionId: "session 3")]
        let sut = createSUT(sessionInfos: sessionInfos, filter: .all)
        var receivedUserSessions = [UserSessionInfo]()
        sut.completion = { result in
            switch result {
            case let .logoutFromUserSessions(sessionInfos: sessionInfos):
                receivedUserSessions = sessionInfos
            default:
                break
            }
        }
        sut.process(viewAction: .logoutAllUserSessions)
        XCTAssertEqual(receivedUserSessions, sessionInfos)
    }
    
    private func toggleEditMode(for model: UserOtherSessionsViewModel, value: Bool) {
        model.context.isEditModeEnabled = value
        model.process(viewAction: .editModeWasToggled)
    }
    
    private func createSUT(sessionInfos: [UserSessionInfo],
                           filter: UserOtherSessionsFilter,
                           title: String = "Title") -> UserOtherSessionsViewModel {
        UserOtherSessionsViewModel(sessionInfos: sessionInfos,
                                   filter: filter,
                                   title: title,
                                   showDeviceLogout: true,
                                   settingsService: MockUserSessionSettings())
    }
    
    private func createUserSessionInfo(sessionId: String,
                                       verificationState: UserSessionInfo.VerificationState = .unverified,
                                       isActive: Bool = true,
                                       isCurrent: Bool = false) -> UserSessionInfo {
        UserSessionInfo(id: sessionId,
                        name: "iOS",
                        deviceType: .mobile,
                        verificationState: verificationState,
                        lastSeenIP: "10.0.0.10",
                        lastSeenTimestamp: Date().timeIntervalSince1970 - 100,
                        applicationName: nil,
                        applicationVersion: nil,
                        applicationURL: nil,
                        deviceModel: "iPhone XS",
                        deviceOS: "iOS 15.5",
                        lastSeenIPLocation: nil,
                        clientName: nil,
                        clientVersion: nil,
                        isActive: isActive,
                        isCurrent: isCurrent)
    }
}
