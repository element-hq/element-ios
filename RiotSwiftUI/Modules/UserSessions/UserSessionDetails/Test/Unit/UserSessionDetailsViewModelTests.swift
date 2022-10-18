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
    private static var lastSeenDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EE, d MMM · HH:mm"
        return dateFormatter
    }()
    
    func test_whenSessionNameAndLastSeenIPNil_viewStateCorrect() {
        let userSessionInfo = createUserSessionInfo(id: "session",
                                                    name: nil,
                                                    lastSeenIP: nil)

        let sessionItems = [
            sessionIdItem(sessionId: "session")
        ]
        
        let sections = [
            UserSessionDetailsSectionViewData(header: VectorL10n.userSessionDetailsSessionSectionHeader.uppercased(),
                                              footer: VectorL10n.userSessionDetailsSessionSectionFooter,
                                              items: sessionItems)
        ]

        let expectedModel = UserSessionDetailsViewState(sections: sections)
        let sut = UserSessionDetailsViewModel(sessionInfo: userSessionInfo)
        
        XCTAssertEqual(sut.state, expectedModel)
    }
    
    func test_whenSessionNameNotNilLastSeenIPNil_viewStateCorrect() {
        let userSessionInfo = createUserSessionInfo(id: "session",
                                                    name: "session name",
                                                    lastSeenIP: nil)

        let sessionItems = [
            sessionNameItem(sessionName: "session name"),
            sessionIdItem(sessionId: "session")
        ]

        let sections = [
            UserSessionDetailsSectionViewData(header: VectorL10n.userSessionDetailsSessionSectionHeader.uppercased(),
                                              footer: VectorL10n.userSessionDetailsSessionSectionFooter,
                                              items: sessionItems)
        ]
        
        let expectedModel = UserSessionDetailsViewState(sections: sections)
        let sut = UserSessionDetailsViewModel(sessionInfo: userSessionInfo)
        
        XCTAssertEqual(sut.state, expectedModel)
    }
    
    func test_whenUserSessionInfoContainsAllValues_viewStateCorrect() {
        let lastSeenTimestamp = Date().timeIntervalSince1970 - 1_000_000
        let userSessionInfo = createUserSessionInfo(id: "session",
                                                    name: "session name",
                                                    lastSeenIP: "0.0.0.0",
                                                    lastSeenTimestamp: lastSeenTimestamp,
                                                    applicationName: "Element iOS",
                                                    applicationVersion: "1.0.0")
        
        let sessionItems = [
            sessionNameItem(sessionName: "session name"),
            sessionIdItem(sessionId: "session"),
            sessionLastActivity(lastSeen: lastSeenTimestamp)
        ]
        let appItems = [
            appNameItem(appName: "Element iOS"),
            appVersionItem(appVersion: "1.0.0")
        ]
        let deviceItems = [
            ipAddressItem(ipAddress: "0.0.0.0")
        ]

        let sections = [
            UserSessionDetailsSectionViewData(header: VectorL10n.userSessionDetailsSessionSectionHeader.uppercased(),
                                              footer: VectorL10n.userSessionDetailsSessionSectionFooter,
                                              items: sessionItems),
            UserSessionDetailsSectionViewData(header: VectorL10n.userSessionDetailsApplicationSectionHeader.uppercased(),
                                              footer: nil,
                                              items: appItems),
            UserSessionDetailsSectionViewData(header: VectorL10n.userSessionDetailsDeviceSectionHeader.uppercased(),
                                              footer: nil,
                                              items: deviceItems)
        ]
        
        let expectedModel = UserSessionDetailsViewState(sections: sections)
        let sut = UserSessionDetailsViewModel(sessionInfo: userSessionInfo)
        
        XCTAssertEqual(sut.state, expectedModel)
    }

    // MARK: - Private
    
    private func createUserSessionInfo(id: String,
                                       name: String?,
                                       deviceType: DeviceType = .mobile,
                                       isVerified: Bool = false,
                                       lastSeenIP: String?,
                                       lastSeenTimestamp: TimeInterval? = nil,
                                       applicationName: String? = nil,
                                       applicationVersion: String? = nil,
                                       applicationURL: String? = nil,
                                       deviceModel: String? = nil,
                                       deviceOS: String? = nil,
                                       lastSeenIPLocation: String? = nil,
                                       clientName: String? = nil,
                                       clientVersion: String? = nil,
                                       isActive: Bool = true,
                                       isCurrent: Bool = true) -> UserSessionInfo {
        UserSessionInfo(id: id,
                        name: name,
                        deviceType: deviceType,
                        verificationState: isVerified ? .verified : .unverified,
                        lastSeenIP: lastSeenIP,
                        lastSeenTimestamp: lastSeenTimestamp,
                        applicationName: applicationName,
                        applicationVersion: applicationVersion,
                        applicationURL: applicationURL,
                        deviceModel: deviceModel,
                        deviceOS: deviceOS,
                        lastSeenIPLocation: lastSeenIPLocation,
                        clientName: clientName,
                        clientVersion: clientVersion,
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
    
    private func sessionLastActivity(lastSeen: TimeInterval) -> UserSessionDetailsSectionItemViewData {
        .init(title: VectorL10n.userSessionDetailsLastActivity,
              value: Self.lastSeenDateFormatter.string(from: Date(timeIntervalSince1970: lastSeen)))
    }

    private func appNameItem(appName: String) -> UserSessionDetailsSectionItemViewData {
        .init(title: VectorL10n.userSessionDetailsApplicationName,
              value: appName)
    }

    private func appVersionItem(appVersion: String) -> UserSessionDetailsSectionItemViewData {
        .init(title: VectorL10n.userSessionDetailsApplicationVersion,
              value: appVersion)
    }

    private func ipAddressItem(ipAddress: String) -> UserSessionDetailsSectionItemViewData {
        .init(title: VectorL10n.userSessionDetailsDeviceIpAddress,
              value: ipAddress)
    }
}
