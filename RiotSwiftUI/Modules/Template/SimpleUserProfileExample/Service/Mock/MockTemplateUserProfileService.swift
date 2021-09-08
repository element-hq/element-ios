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
import Combine

@available(iOS 14.0, *)
class MockTemplateUserProfileService: TemplateUserProfileServiceProtocol {

    static let example = MockTemplateUserProfileService()
    static let initialPresenceState: TemplateUserProfilePresence = .offline
    @Published var presence: TemplateUserProfilePresence = initialPresenceState
    var presencePublisher: AnyPublisher<TemplateUserProfilePresence, Never> {
        $presence.eraseToAnyPublisher()
    }
    let userId: String = "123"
    let displayName: String? = "Alice"
    let avatarUrl: String? = "mx123@matrix.com"
    let currentlyActive: Bool = true
    let lastActive: UInt = 1630596918513
    
    func simulateUpdate(presence: TemplateUserProfilePresence) {
        self.presence = presence
    }
}
