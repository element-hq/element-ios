// File created from SimpleUserProfileExample
// $ createScreen.sh Spaces/SpaceCreation/SpaceCreationEmailInvites SpaceCreationEmailInvites
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
enum MockSpaceCreationEmailInvitesScreenState: MockScreenState, CaseIterable {
    // A case for each state you want to represent
    // with specific, minimal associated data that will allow you
    // mock that screen.
    case defaultEmailValues
    case emailEntered
    case emailValidationFailed
    case loading

    /// The associated screen
    var screenType: Any.Type {
        SpaceCreationEmailInvites.self
    }
    
    /// A list of screen state definitions
    static var allCases: [MockSpaceCreationEmailInvitesScreenState] {
        [.defaultEmailValues, .emailEntered, .emailValidationFailed, .loading]
    }
    
    /// Generate the view struct for the screen state.
    var screenView: ([Any], AnyView) {
        let creationParams = SpaceCreationParameters()
        let service: MockSpaceCreationEmailInvitesService
        switch self {
        case .defaultEmailValues:
            service = MockSpaceCreationEmailInvitesService(defaultValidation: true, isLoading: false)
        case .emailEntered:
            creationParams.emailInvites = ["test1@element.io", "test2@element.io"]
            service = MockSpaceCreationEmailInvitesService(defaultValidation: true, isLoading: false)
        case .emailValidationFailed:
            creationParams.emailInvites = ["test1@element.io", "test2@element.io"]
            service = MockSpaceCreationEmailInvitesService(defaultValidation: false, isLoading: false)
        case .loading:
            creationParams.emailInvites = ["test1@element.io", "test2@element.io"]
            service = MockSpaceCreationEmailInvitesService(defaultValidation: true, isLoading: true)
        }
        let viewModel = SpaceCreationEmailInvitesViewModel(creationParameters: creationParams, service: service)
        
        // can simulate service and viewModel actions here if needs be.
        
        return (
            [viewModel],
            AnyView(SpaceCreationEmailInvites(viewModel: viewModel.context)
                .environmentObject(AvatarViewModel.withMockedServices()))
        )
    }
}
