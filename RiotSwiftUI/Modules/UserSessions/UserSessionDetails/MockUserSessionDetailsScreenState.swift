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

import SwiftUI

/// Using an enum for the screen allows you define the different state cases with
/// the relevant associated data for each case.
enum MockUserSessionDetailsScreenState: MockScreenState, CaseIterable {
    // A case for each state you want to represent
    // with specific, minimal associated data that will allow you
    // mock that screen.
    case allSections
    case sessionSectionOnly
    
    /// The associated screen
    var screenType: Any.Type {
        UserSessionDetails.self
    }
    
    /// A list of screen state definitions
    static var allCases: [MockUserSessionDetailsScreenState] {
        // Each of the presence statuses
        return [.allSections, sessionSectionOnly]
    }
    
    /// Generate the view struct for the screen state.
    var screenView: ([Any], AnyView)  {
        let currentSessionInfo: UserSessionInfo
        switch self {
        case .allSections:
            currentSessionInfo = UserSessionInfo(sessionId: "session",
                                                 sessionName: "iOS",
                                                 deviceType: .mobile,
                                                 isVerified: false,
                                                 lastSeenIP: "10.0.0.10",
                                                 lastSeenTimestamp: Date().timeIntervalSince1970 - 100,
                                                 applicationName: "Element iOS",
                                                 applicationVersion: "1.0.0",
                                                 applicationURL: nil)
        case .sessionSectionOnly:
            currentSessionInfo = UserSessionInfo(sessionId: "session",
                                                 sessionName: "iOS",
                                                 deviceType: .mobile,
                                                 isVerified: false,
                                                 lastSeenIP: nil,
                                                 lastSeenTimestamp: Date().timeIntervalSince1970 - 100,
                                                 applicationName: nil,
                                                 applicationVersion: nil,
                                                 applicationURL: nil)
        }
        let viewModel = UserSessionDetailsViewModel(userSessionInfo: currentSessionInfo)
        
        // can simulate service and viewModel actions here if needs be.
        
        return (
            [currentSessionInfo],
            AnyView(UserSessionDetails(viewModel: viewModel.context))
        )
    }
}
