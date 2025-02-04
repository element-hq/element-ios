//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
        
        let viewModel = UserSessionsOverviewViewModel(userSessionsOverviewService: service, settingsService: MockUserSessionSettings(), showDeviceLogout: true)
        
        return (
            [service, viewModel],
            AnyView(UserSessionsOverview(viewModel: viewModel.context)
                .environmentObject(AvatarViewModel.withMockedServices()))
        )
    }
}
