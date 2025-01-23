// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// Describes service that monitor and share current user device location to rooms where user shared is location
protocol UserLocationServiceProtocol {
    
    /// Request location permissions that enables live location sharing
    func requestAuthorization(_ handler: @escaping LocationAuthorizationHandler)

    /// Start monitoring user location and look to rooms where location should be sent
    func start()
    
    /// Stop monitoring user location
    func stop()
}
