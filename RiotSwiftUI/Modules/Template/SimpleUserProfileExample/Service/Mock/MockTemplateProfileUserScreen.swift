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

/**
 Using an enum for the screen allows you define the different state cases with
 the relevant associated data for each case.
 */
@available(iOS 14.0, *)
enum MockTemplateProfileUserScreenStates: MockScreen {
    
    case mockPresenceStates(TemplateUserProfilePresence)
    case mockLongDisplayName(String)
    
    static var screenStates: [MockTemplateProfileUserScreenStates] = TemplateUserProfilePresence.allCases.map(MockTemplateProfileUserScreenStates.mockPresenceStates)
        + [.mockLongDisplayName("Somebody with a super long name we would like to test")]
    
    static func screen(for state: MockTemplateProfileUserScreenStates) -> some View {
        let service: MockTemplateUserProfileService
        switch state {
        case .mockPresenceStates(let presence):
            service = MockTemplateUserProfileService(presence: presence)
        case .mockLongDisplayName(let displayName):
            service = MockTemplateUserProfileService(displayName: displayName)
        }
        let viewModel = TemplateUserProfileViewModel(userService: service)
        return TemplateUserProfile(viewModel: viewModel)
                .addDependency(MockAvatarService.example)
    }
}
