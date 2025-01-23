// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import AnalyticsEvents

extension UserSessionProperties.UseCase {
    var analyticsName: AnalyticsEvent.UserProperties.FtueUseCaseSelection {
        switch self {
        case .personalMessaging:
            return .PersonalMessaging
        case .workMessaging:
            return .WorkMessaging
        case .communityMessaging:
            return .CommunityMessaging
        case .skipped:
            return .Skip
        }
    }
}
