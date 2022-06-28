// File created from TemplateAdvancedRoomsExample
// $ createSwiftUITwoScreen.sh Spaces/SpaceCreation SpaceCreation SpaceCreationMenu SpaceCreationSettings
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
enum MockSpaceCreationSettingsScreenState: MockScreenState, CaseIterable {
    // A case for each state you want to represent
    // with specific, minimal associated data that will allow you
    // mock that screen.
    case privateSpace
    case validated
    case validationFailed
    
    /// The associated screen
    var screenType: Any.Type {
        SpaceCreationSettings.self
    }
    
    /// Generate the view struct for the screen state.
    var screenView: ([Any], AnyView) {
        let creationParameters = SpaceCreationParameters()
        creationParameters.name = "Fake"

        let service: MockSpaceCreationSettingsService = MockSpaceCreationSettingsService()
        switch self {
        case .privateSpace:
            creationParameters.isPublic = false
        case .validated:
            creationParameters.isPublic = true
            service.simulateUpdate(addressValidationStatus: .valid("#fake:fake-domain.org"))
        case .validationFailed:
            creationParameters.isPublic = true
            creationParameters.topic = "Some short description"
            creationParameters.userDefinedAddress = "fake-uri"
            service.simulateUpdate(addressValidationStatus: .alreadyExists("#fake-uri:fake-domain.org"))
            creationParameters.userSelectedAvatar = Asset.Images.appSymbol.image
        }

        let viewModel = SpaceCreationSettingsViewModel(spaceCreationSettingsService: service, creationParameters: creationParameters)
        
        return (
            [service, viewModel],
            AnyView(SpaceCreationSettings(viewModel: viewModel.context)
                        .addDependency(MockAvatarService.example))
        )
    }
}
