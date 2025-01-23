// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import AnalyticsEvents

extension MXTaskProfileName {
    var analyticsName: AnalyticsEvent.PerformanceTimer.Name? {
        switch self {
        case .startupIncrementalSync:
            return .StartupIncrementalSync
        case .startupInitialSync:
            return .StartupInitialSync
        case .startupLaunchScreen:
            return .StartupLaunchScreen
        case .startupStorePreload:
            return .StartupStorePreload
        case .startupMountData:
            return .StartupStoreReady
        case .initialSyncRequest:
            return .InitialSyncRequest
        case .initialSyncParsing:
            return .InitialSyncParsing
        case .notificationsOpenEvent:
            return .NotificationsOpenEvent
        default:
            return nil
        }
    }
}
