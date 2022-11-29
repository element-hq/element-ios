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

import Foundation
import SwiftUI

/// Using an enum for the screen allows you define the different state cases with
/// the relevant associated data for each case.
enum MockUserSessionOverviewScreenState: MockScreenState, CaseIterable {
    // A case for each state you want to represent
    // with specific, minimal associated data that will allow you
    // mock that screen.
    case currentSession(sessionState: UserSessionInfo.VerificationState)
    case otherSession(sessionState: UserSessionInfo.VerificationState)
    case sessionWithPushNotifications(enabled: Bool)
    case remotelyTogglingPushersNotAvailable

    /// The associated screen
    var screenType: Any.Type {
        UserSessionOverview.self
    }
    
    /// A list of screen state definitions
    static var allCases: [MockUserSessionOverviewScreenState] {
        [.currentSession(sessionState: .unverified),
         .currentSession(sessionState: .verified),
         .otherSession(sessionState: .verified),
         .otherSession(sessionState: .unverified),
         .otherSession(sessionState: .permanentlyUnverified),
         .sessionWithPushNotifications(enabled: true),
         .sessionWithPushNotifications(enabled: false),
         .remotelyTogglingPushersNotAvailable]
    }
    
    /// Generate the view struct for the screen state.
    var screenView: ([Any], AnyView) {
        let session: UserSessionInfo
        let service: UserSessionOverviewServiceProtocol
        switch self {
        case .currentSession(let state):
            session = UserSessionInfo(id: "alice",
                                      name: "iOS",
                                      deviceType: .mobile,
                                      verificationState: state,
                                      lastSeenIP: "10.0.0.10",
                                      lastSeenTimestamp: nil,
                                      applicationName: "Element iOS",
                                      applicationVersion: "1.0.0",
                                      applicationURL: nil,
                                      deviceModel: nil,
                                      deviceOS: "iOS 15.5",
                                      lastSeenIPLocation: nil,
                                      clientName: "Element",
                                      clientVersion: "1.0.0",
                                      isActive: true,
                                      isCurrent: true)
            service = MockUserSessionOverviewService()
        case .otherSession(let state):
            session = UserSessionInfo(id: "1",
                                      name: "macOS",
                                      deviceType: .desktop,
                                      verificationState: state,
                                      lastSeenIP: "1.0.0.1",
                                      lastSeenTimestamp: Date().timeIntervalSince1970 - 130_000,
                                      applicationName: "Element MacOS",
                                      applicationVersion: "1.0.0",
                                      applicationURL: nil,
                                      deviceModel: nil,
                                      deviceOS: "macOS",
                                      lastSeenIPLocation: nil,
                                      clientName: "Electron",
                                      clientVersion: "20.1.1",
                                      isActive: false,
                                      isCurrent: false)
            service = MockUserSessionOverviewService()
        case .sessionWithPushNotifications(let enabled):
            session = UserSessionInfo(id: "1",
                                      name: "macOS",
                                      deviceType: .desktop,
                                      verificationState: .verified,
                                      lastSeenIP: "1.0.0.1",
                                      lastSeenTimestamp: Date().timeIntervalSince1970 - 130_000,
                                      applicationName: "Element MacOS",
                                      applicationVersion: "1.0.0",
                                      applicationURL: nil,
                                      deviceModel: nil,
                                      deviceOS: "macOS",
                                      lastSeenIPLocation: nil,
                                      clientName: "My Mac",
                                      clientVersion: "1.0.0",
                                      isActive: false,
                                      isCurrent: false)
            service = MockUserSessionOverviewService(pusherEnabled: enabled)
        case .remotelyTogglingPushersNotAvailable:
            session = UserSessionInfo(id: "1",
                                      name: "macOS",
                                      deviceType: .desktop,
                                      verificationState: .verified,
                                      lastSeenIP: "1.0.0.1",
                                      lastSeenTimestamp: Date().timeIntervalSince1970 - 130_000,
                                      applicationName: "Element MacOS",
                                      applicationVersion: "1.0.0",
                                      applicationURL: nil,
                                      deviceModel: nil,
                                      deviceOS: "macOS",
                                      lastSeenIPLocation: nil,
                                      clientName: "My Mac",
                                      clientVersion: "1.0.0",
                                      isActive: false,
                                      isCurrent: false)
            service = MockUserSessionOverviewService(pusherEnabled: true, remotelyTogglingPushersAvailable: false)
        }

        let viewModel = UserSessionOverviewViewModel(sessionInfo: session, service: service, settingsService: MockUserSessionSettings())
        // can simulate service and viewModel actions here if needs be.
        return ([viewModel], AnyView(UserSessionOverview(viewModel: viewModel.context)))
    }
}

extension MockUserSessionOverviewScreenState: CustomStringConvertible {
    var description: String {
        switch self {
        case .currentSession(let sessionState):
            return "currentSession\(sessionState)"
        case .otherSession(let sessionState):
            return "otherSession\(sessionState)"
        case .remotelyTogglingPushersNotAvailable:
            return "remotelyTogglingPushersNotAvailable"
        case .sessionWithPushNotifications(let enabled):
            return "sessionWithPushNotifications\(enabled)"
        }
    }
}
