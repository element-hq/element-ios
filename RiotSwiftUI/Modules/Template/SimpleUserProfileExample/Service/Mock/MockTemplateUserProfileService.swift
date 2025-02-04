//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

class MockTemplateUserProfileService: TemplateUserProfileServiceProtocol {
    var presenceSubject: CurrentValueSubject<TemplateUserProfilePresence, Never>
    
    let userId: String
    let displayName: String?
    let avatarUrl: String?
    init(userId: String = "@alice:matrix.org",
         displayName: String? = "Alice",
         avatarUrl: String? = "mxc://matrix.org/VyNYAgahaiAzUoOeZETtQ",
         presence: TemplateUserProfilePresence = .offline) {
        self.userId = userId
        self.displayName = displayName
        self.avatarUrl = avatarUrl
        presenceSubject = CurrentValueSubject<TemplateUserProfilePresence, Never>(presence)
    }
    
    func simulateUpdate(presence: TemplateUserProfilePresence) {
        presenceSubject.value = presence
    }
}
