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
enum MockSpaceSettingsScreenState: MockScreenState, CaseIterable {
    // A case for each state you want to represent
    // with specific, minimal associated data that will allow you
    // mock that screen.
    case visibility(SpaceSettingsVisibility)
    case notEditable

    /// The associated screen
    var screenType: Any.Type {
        SpaceSettings.self
    }
    
    /// A list of screen state definitions
    static var allCases: [MockSpaceSettingsScreenState] {
        SpaceSettingsVisibility.allCases.map(MockSpaceSettingsScreenState.visibility)
            + [.notEditable]
    }
    
    /// Generate the view struct for the screen state.
    var screenView: ([Any], AnyView)  {
        let service: MockSpaceSettingsService
        switch self {
        case .visibility(let visibility):
            let roomProperties = SpaceSettingsRoomProperties(
                name: "Space Name",
                topic: "Sapce topic",
                address: nil,
                avatarUrl: nil,
                visibility: visibility,
                allowedParentIds: [],
                isAvatarEditable: true,
                isNameEditable: true,
                isTopicEditable: true,
                isAddressEditable: true,
                isAccessEditable: true)
            service = MockSpaceSettingsService(roomProperties: roomProperties)
        case .notEditable:
            let roomProperties = SpaceSettingsRoomProperties(
                name: "Space Name",
                topic: "Sapce topic",
                address: nil,
                avatarUrl: nil,
                visibility: .public,
                allowedParentIds: [],
                isAvatarEditable: false,
                isNameEditable: false,
                isTopicEditable: false,
                isAddressEditable: false,
                isAccessEditable: false)
            service = MockSpaceSettingsService(roomProperties: roomProperties)
        }
        let viewModel = SpaceSettingsViewModel.makeSpaceSettingsViewModel(service: service)
        
        // can simulate service and viewModel actions here if needs be.
        
        return (
            [service, viewModel],
            AnyView(SpaceSettings(viewModel: viewModel.context)
                .addDependency(MockAvatarService.example))
        )
    }
}
