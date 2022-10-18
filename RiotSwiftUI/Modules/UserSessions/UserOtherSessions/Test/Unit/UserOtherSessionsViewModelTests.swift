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

@testable import RiotSwiftUI

class UserOtherSessionsViewModelTests: XCTestCase {
    private let unverifiedSectionHeader = UserOtherSessionsHeaderViewData(title: VectorL10n.userSessionUnverifiedShort,
                                                                          subtitle: VectorL10n.userOtherSessionUnverifiedSessionsHeaderSubtitle,
                                                                          iconName: Asset.Images.userOtherSessionsUnverified.name)
    
    private let inactiveSectionHeader = UserOtherSessionsHeaderViewData(title: VectorL10n.userOtherSessionFilterMenuInactive,
                                                                        subtitle: VectorL10n.userSessionsOverviewSecurityRecommendationsInactiveInfo,
                                                                        iconName: Asset.Images.userOtherSessionsInactive.name)
    
    private let allSectionHeader = UserOtherSessionsHeaderViewData(title: nil,
                                                                   subtitle: VectorL10n.userSessionsOverviewOtherSessionsSectionInfo,
                                                                   iconName: nil)
    
    private let verifiedSectionHeader = UserOtherSessionsHeaderViewData(title: VectorL10n.userOtherSessionFilterMenuVerified,
                                                                        subtitle: VectorL10n.userOtherSessionVerifiedSessionsHeaderSubtitle,
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
        let expectedState = UserOtherSessionsViewState(bindings: UserOtherSessionsBindings(filter: .inactive),
                                                       title: "Title",
                                                       sections: [.sessionItems(header: inactiveSectionHeader, items: expectedItems)])
        XCTAssertEqual(sut.state, expectedState)
    }
    
    func test_whenModelCreated_withAllFilter_viewStateIsCorrect() {
        let sessionInfos = [createUserSessionInfo(sessionId: "session 1"),
                            createUserSessionInfo(sessionId: "session 2")]
        let sut = createSUT(sessionInfos: sessionInfos, filter: .all)
        
        let expectedItems = sessionInfos.filter { !$0.isCurrent }.asViewData()
        let expectedState = UserOtherSessionsViewState(bindings: UserOtherSessionsBindings(filter: .all),
                                                       title: "Title",
                                                       sections: [.sessionItems(header: allSectionHeader, items: expectedItems)])
        XCTAssertEqual(sut.state, expectedState)
    }
    
    func test_whenModelCreated_withUnverifiedFilter_viewStateIsCorrect() {
        let sessionInfos = [createUserSessionInfo(sessionId: "session 1"),
                            createUserSessionInfo(sessionId: "session 2")]
        let sut = createSUT(sessionInfos: sessionInfos, filter: .unverified)
        
        let expectedItems = sessionInfos.filter { !$0.isCurrent }.asViewData()
        let expectedState = UserOtherSessionsViewState(bindings: UserOtherSessionsBindings(filter: .unverified),
                                                       title: "Title",
                                                       sections: [.sessionItems(header: unverifiedSectionHeader, items: expectedItems)])
        XCTAssertEqual(sut.state, expectedState)
    }
    
    func test_whenModelCreated_withVerifiedFilter_viewStateIsCorrect() {
        let sessionInfos = [createUserSessionInfo(sessionId: "session 1", isVerified: true),
                            createUserSessionInfo(sessionId: "session 2", isVerified: true)]
        let sut = createSUT(sessionInfos: sessionInfos, filter: .verified)
        
        let expectedItems = sessionInfos.filter { !$0.isCurrent }.asViewData()
        let expectedState = UserOtherSessionsViewState(bindings: UserOtherSessionsBindings(filter: .verified),
                                                       title: "Title",
                                                       sections: [.sessionItems(header: verifiedSectionHeader, items: expectedItems)])
        XCTAssertEqual(sut.state, expectedState)
    }
    
    func test_whenModelCreated_withVerifiedFilterWithNoVerifiedSessions_viewStateIsCorrect() {
        let sessionInfos = [createUserSessionInfo(sessionId: "session 1", isVerified: false),
                            createUserSessionInfo(sessionId: "session 2", isVerified: false)]
        let sut = createSUT(sessionInfos: sessionInfos, filter: .verified)
        
        let expectedState = UserOtherSessionsViewState(bindings: UserOtherSessionsBindings(filter: .verified),
                                                       title: "Title",
                                                       sections: [.emptySessionItems(header: verifiedSectionHeader, title: VectorL10n.userOtherSessionNoVerifiedSessions)])
        XCTAssertEqual(sut.state, expectedState)
    }
    
    func test_whenModelCreated_withUnverifiedFilterWithNoUnverifiedSessions_viewStateIsCorrect() {
        let sessionInfos = [createUserSessionInfo(sessionId: "session 1", isVerified: true),
                            createUserSessionInfo(sessionId: "session 2", isVerified: true)]
        let sut = createSUT(sessionInfos: sessionInfos, filter: .unverified)
        
        let expectedState = UserOtherSessionsViewState(bindings: UserOtherSessionsBindings(filter: .unverified),
                                                       title: "Title",
                                                       sections: [.emptySessionItems(header: unverifiedSectionHeader, title: VectorL10n.userOtherSessionNoUnverifiedSessions)])
        XCTAssertEqual(sut.state, expectedState)
    }
    
    func test_whenModelCreated_withInactiveFilterWithNoInactiveSessions_viewStateIsCorrect() {
        let sessionInfos = [createUserSessionInfo(sessionId: "session 1", isActive: true),
                            createUserSessionInfo(sessionId: "session 2", isActive: true)]
        let sut = createSUT(sessionInfos: sessionInfos, filter: .inactive)
        
        let expectedState = UserOtherSessionsViewState(bindings: UserOtherSessionsBindings(filter: .inactive),
                                                       title: "Title",
                                                       sections: [.emptySessionItems(header: inactiveSectionHeader, title: VectorL10n.userOtherSessionNoInactiveSessions)])
        XCTAssertEqual(sut.state, expectedState)
    }
    
    private func createSUT(sessionInfos: [UserSessionInfo],
                           filter: UserOtherSessionsFilter,
                           title: String = "Title") -> UserOtherSessionsViewModel {
        UserOtherSessionsViewModel(sessionInfos: sessionInfos,
                                   filter: filter,
                                   title: title)
    }
    
    private func createUserSessionInfo(sessionId: String,
                                       isVerified: Bool = false,
                                       isActive: Bool = true,
                                       isCurrent: Bool = false) -> UserSessionInfo {
        UserSessionInfo(id: sessionId,
                        name: "iOS",
                        deviceType: .mobile,
                        verificationState: isVerified ? .verified : .unverified,
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
