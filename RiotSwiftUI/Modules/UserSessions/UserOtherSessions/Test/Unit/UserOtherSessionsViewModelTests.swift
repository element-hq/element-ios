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
    
    
    func test_whenUserOtherSessionSelectedProcessed_completionWithShowUserSessionOverviewCalled() {
        let expectedUserSessionInfo = createUserSessionInfo(sessionId: "session 2")
        let sut = UserOtherSessionsViewModel(sessionsInfo: [createUserSessionInfo(sessionId: "session 1"),
                                                        expectedUserSessionInfo],
                                         filter: .inactive,
                                         title: "Title")
        
        var modelResult: UserOtherSessionsViewModelResult?
        sut.completion = { result in
            modelResult = result
        }
        sut.process(viewAction: .userOtherSessionSelected(sessionId: expectedUserSessionInfo.id))
        XCTAssertEqual(modelResult, .showUserSessionOverview(sessionInfo: expectedUserSessionInfo))
    }
    
    func test_whenModelCreated_withInactiveFilter_viewStateIsCorrect() {
        let sessionsInfo = [createUserSessionInfo(sessionId: "session 1"), createUserSessionInfo(sessionId: "session 2")]
        let sut = UserOtherSessionsViewModel(sessionsInfo: sessionsInfo,
                                         filter: .inactive,
                                         title: "Title")
        
        let expectedHeader = UserOtherSessionsHeaderViewData(title: VectorL10n.userSessionsOverviewSecurityRecommendationsInactiveTitle,
                                                             subtitle: VectorL10n.userSessionsOverviewSecurityRecommendationsInactiveInfo,
                                                             iconName: Asset.Images.userOtherSessionsInactive.name)
        let expectedItems = sessionsInfo.filter { !$0.isActive }.asViewData()
        let expectedState = UserOtherSessionsViewState(title: "Title",
                                                       sections: [.sessionItems(header: expectedHeader, items: expectedItems)])
        XCTAssertEqual(sut.state, expectedState)
    }
    
    
    private func createUserSessionInfo(sessionId: String) -> UserSessionInfo {
        UserSessionInfo(id: sessionId,
                        name: "iOS",
                        deviceType: .mobile,
                        isVerified: false,
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
                        isActive: true,
                        isCurrent: true)
    }
}
