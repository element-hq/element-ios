//
// Copyright 2022 New Vector Ltd
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
enum MockUserSessionsOverviewScreenState: MockScreenState, CaseIterable {
    case currentSessionUnverified
    case currentSessionVerified
    case onlyUnverifiedSessions
    case onlyInactiveSessions
    case noOtherSessions
    
    /// The associated screen
    var screenType: Any.Type {
        UserSessionsOverview.self
    }
    
    /// Generate the view struct for the screen state.
    var screenView: ([Any], AnyView) {
        var service: UserSessionsOverviewServiceProtocol?
        switch self {
        case .currentSessionUnverified:
            service = MockUserSessionsOverviewService(mode: .currentSessionUnverified)
        case .currentSessionVerified:
            service = MockUserSessionsOverviewService(mode: .currentSessionVerified)
        case .onlyUnverifiedSessions:
            service = MockUserSessionsOverviewService(mode: .onlyUnverifiedSessions)
        case .onlyInactiveSessions:
            service = MockUserSessionsOverviewService(mode: .onlyInactiveSessions)
        case .noOtherSessions:
            service = MockUserSessionsOverviewService(mode: .noOtherSessions)
        }
        
        guard let service = service else {
            fatalError()
        }
        
        let viewModel = UserSessionsOverviewViewModel(userSessionsOverviewService: service, settingsService: MockUserSessionSettings())
        
        return (
            [service, viewModel],
            AnyView(UserSessionsOverview(viewModel: viewModel.context)
                .addDependency(MockAvatarService.example))
        )
    }
}
