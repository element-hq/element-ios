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

class UserSessionDetailsViewModelTests: XCTestCase {
    func test_whenSessionNameAndLastSeenIPNil_viewStateCorrect() {
        let userSessionInfo = createUserSessionInfo(id: "session",
                                                    name: nil,
                                                    lastSeenIP: nil)

        var sessionItems: [UserSessionDetailsSectionItemViewData] = []
        sessionItems.append(sessionIdItem(sessionId: userSessionInfo.id))
        
        var sections: [UserSessionDetailsSectionViewData] = []
        sections.append(.init(header: VectorL10n.userSessionDetailsSessionSectionHeader.uppercased(),
                              footer: VectorL10n.userSessionDetailsSessionSectionFooter,
                              items: sessionItems))
        let expectedModel = UserSessionDetailsViewState(sections: sections)
        let sut = UserSessionDetailsViewModel(session: userSessionInfo)
        
        XCTAssertEqual(sut.state, expectedModel)
    }
    
    func test_whenSessionNameNotNilLastSeenIPNil_viewStateCorrect() {
        let userSessionInfo = createUserSessionInfo(id: "session",
                                                    name: "session name",
                                                    lastSeenIP: nil)
        
        var sessionItems = [UserSessionDetailsSectionItemViewData]()
        sessionItems.append(sessionNameItem(sessionName: "session name"))
        sessionItems.append(sessionIdItem(sessionId: userSessionInfo.id))

        var sections: [UserSessionDetailsSectionViewData] = []
        sections.append(.init(header: VectorL10n.userSessionDetailsSessionSectionHeader.uppercased(),
                              footer: VectorL10n.userSessionDetailsSessionSectionFooter,
                              items: sessionItems))
        
        let expectedModel = UserSessionDetailsViewState(sections: sections)
        let sut = UserSessionDetailsViewModel(session: userSessionInfo)
        
        XCTAssertEqual(sut.state, expectedModel)
    }
    
    func test_whenUserSessionInfoContainsAllValues_viewStateCorrect() {
        let userSessionInfo = createUserSessionInfo(id: "session",
                                                    name: "session name",
                                                    lastSeenIP: "0.0.0.0")
        
        var sessionItems: [UserSessionDetailsSectionItemViewData] = []
        sessionItems.append(sessionNameItem(sessionName: "session name"))
        sessionItems.append(sessionIdItem(sessionId: userSessionInfo.id))

        var sections: [UserSessionDetailsSectionViewData] = []
        sections.append(.init(header: VectorL10n.userSessionDetailsSessionSectionHeader.uppercased(),
                              footer: VectorL10n.userSessionDetailsSessionSectionFooter,
                              items: sessionItems))
        
        var deviceSectionItems: [UserSessionDetailsSectionItemViewData] = []
        deviceSectionItems.append(.init(title: VectorL10n.userSessionDetailsDeviceIpAddress,
                                        value: "0.0.0.0"))
        sections.append(.init(header: VectorL10n.userSessionDetailsDeviceSectionHeader.uppercased(),
                              footer: nil,
                              items: deviceSectionItems))
        
        let expectedModel = UserSessionDetailsViewState(sections: sections)
        let sut = UserSessionDetailsViewModel(session: userSessionInfo)
        
        XCTAssertEqual(sut.state, expectedModel)
    }
    
    private func createUserSessionInfo(id: String,
                                       name: String?,
                                       deviceType: DeviceType = .mobile,
                                       isVerified: Bool = false,
                                       lastSeenIP: String?,
                                       lastSeenTimestamp: TimeInterval = Date().timeIntervalSince1970,
                                       applicationName: String? = "Element iOS",
                                       applicationVersion: String? = "1.0.0",
                                       applicationURL: String? = nil,
                                       deviceModel: String? = nil,
                                       deviceOS: String? = nil,
                                       lastSeenIPLocation: String? = nil,
                                       deviceName: String? = nil,
                                       isActive: Bool = true,
                                       isCurrent: Bool = true) -> UserSessionInfo {
        UserSessionInfo(id: id,
                        name: name,
                        deviceType: deviceType,
                        isVerified: isVerified,
                        lastSeenIP: lastSeenIP,
                        lastSeenTimestamp: lastSeenTimestamp,
                        applicationName: applicationName,
                        applicationVersion: applicationVersion,
                        applicationURL: applicationURL,
                        deviceModel: deviceModel,
                        deviceOS: deviceOS,
                        lastSeenIPLocation: lastSeenIPLocation,
                        deviceName: deviceName,
                        isActive: isActive,
                        isCurrent: isCurrent)
    }
    
    private func sessionNameItem(sessionName: String) -> UserSessionDetailsSectionItemViewData {
        .init(title: VectorL10n.userSessionDetailsSessionName,
              value: sessionName)
    }
    
    private func sessionIdItem(sessionId: String) -> UserSessionDetailsSectionItemViewData {
        .init(title: VectorL10n.keyVerificationManuallyVerifyDeviceIdTitle,
              value: sessionId)
    }
}
