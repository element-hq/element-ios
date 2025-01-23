//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

class MockUserSessionOverviewService: UserSessionOverviewServiceProtocol {
    var pusherEnabledSubject: CurrentValueSubject<Bool?, Never>
    var remotelyTogglingPushersAvailableSubject: CurrentValueSubject<Bool, Never>

    init(pusherEnabled: Bool? = nil, remotelyTogglingPushersAvailable: Bool = true) {
        pusherEnabledSubject = CurrentValueSubject(pusherEnabled)
        remotelyTogglingPushersAvailableSubject = CurrentValueSubject(remotelyTogglingPushersAvailable)
    }
    
    func togglePushNotifications() {
        guard let enabled = pusherEnabledSubject.value, remotelyTogglingPushersAvailableSubject.value else {
            return
        }
        
        pusherEnabledSubject.send(!enabled)
    }
}
