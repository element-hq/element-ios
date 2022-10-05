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
enum MockUserOtherSessionsScreenState: MockScreenState, CaseIterable {
    // A case for each state you want to represent
    // with specific, minimal associated data that will allow you
    // mock that screen.

    case inactiveSessions
    
    /// The associated screen
    var screenType: Any.Type {
        UserOtherSessions.self
    }
    
    /// A list of screen state definitions
    static var allCases: [MockUserOtherSessionsScreenState] {
        // Each of the presence statuses
        [.inactiveSessions]
    }
    
    /// Generate the view struct for the screen state.
    var screenView: ([Any], AnyView) {
        
        let viewModel = UserOtherSessionsViewModel(sessionsInfo: inactiveSessions(),
                                                   filter: .inactive,
                                                   title: VectorL10n.userOtherSessionSecurityRecommendationTitle)

        // can simulate service and viewModel actions here if needs be.
        
        return (
            [viewModel],
            AnyView(UserOtherSessions(viewModel: viewModel.context))
        )
    }
    
    private func inactiveSessions() -> [UserSessionInfo] {
        [UserSessionInfo(id: "0",
                         name: "iOS",
                         deviceType: .mobile,
                         isVerified: false,
                         lastSeenIP: "10.0.0.10",
                         lastSeenTimestamp: nil,
                         applicationName: nil,
                         applicationVersion: nil,
                         applicationURL: nil,
                         deviceModel: nil,
                         deviceOS: nil,
                         lastSeenIPLocation: nil,
                         clientName: nil,
                         clientVersion: nil,
                         isActive: false,
                         isCurrent: true),
         UserSessionInfo(id: "1",
                         name: "macOS",
                         deviceType: .desktop,
                         isVerified: true,
                         lastSeenIP: "1.0.0.1",
                         lastSeenTimestamp: Date().timeIntervalSince1970 - 8000000,
                         applicationName: nil,
                         applicationVersion: nil,
                         applicationURL: nil,
                         deviceModel: nil,
                         deviceOS: nil,
                         lastSeenIPLocation: nil,
                         clientName: nil,
                         clientVersion: nil,
                         isActive: false,
                         isCurrent: false),
         UserSessionInfo(id: "2",
                         name: "Firefox on Windows",
                         deviceType: .web,
                         isVerified: true,
                         lastSeenIP: "2.0.0.2",
                         lastSeenTimestamp: Date().timeIntervalSince1970 - 9000000,
                         applicationName: nil,
                         applicationVersion: nil,
                         applicationURL: nil,
                         deviceModel: nil,
                         deviceOS: nil,
                         lastSeenIPLocation: nil,
                         clientName: nil,
                         clientVersion: nil,
                         isActive: false,
                         isCurrent: false),
         UserSessionInfo(id: "3",
                         name: "Android",
                         deviceType: .mobile,
                         isVerified: false,
                         lastSeenIP: "3.0.0.3",
                         lastSeenTimestamp: Date().timeIntervalSince1970 - 10000000,
                         applicationName: nil,
                         applicationVersion: nil,
                         applicationURL: nil,
                         deviceModel: nil,
                         deviceOS: nil,
                         lastSeenIPLocation: nil,
                         clientName: nil,
                         clientVersion: nil,
                         isActive: false,
                         isCurrent: false)]
    }
}
