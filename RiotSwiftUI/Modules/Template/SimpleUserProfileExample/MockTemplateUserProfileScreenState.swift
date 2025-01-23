//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import SwiftUI

/// Using an enum for the screen allows you define the different state cases with
/// the relevant associated data for each case.
enum MockTemplateUserProfileScreenState: MockScreenState, CaseIterable {
    // A case for each state you want to represent
    // with specific, minimal associated data that will allow you
    // mock that screen.
    case presence(TemplateUserProfilePresence)
    case longDisplayName(String)
    
    /// The associated screen
    var screenType: Any.Type {
        TemplateUserProfile.self
    }
    
    /// A list of screen state definitions
    static var allCases: [MockTemplateUserProfileScreenState] {
        // Each of the presence statuses
        TemplateUserProfilePresence.allCases.map(MockTemplateUserProfileScreenState.presence)
            // A long display name
            + [.longDisplayName("Somebody with a super long name we would like to test")]
    }
    
    /// Generate the view struct for the screen state.
    var screenView: ([Any], AnyView) {
        let service: MockTemplateUserProfileService
        switch self {
        case .presence(let presence):
            service = MockTemplateUserProfileService(presence: presence)
        case .longDisplayName(let displayName):
            service = MockTemplateUserProfileService(displayName: displayName)
        }
        let viewModel = TemplateUserProfileViewModel.makeTemplateUserProfileViewModel(templateUserProfileService: service)
        
        // can simulate service and viewModel actions here if needs be.
        
        return (
            [service, viewModel],
            AnyView(TemplateUserProfile(viewModel: viewModel.context)
                .environmentObject(AvatarViewModel.withMockedServices()))
        )
    }
}
