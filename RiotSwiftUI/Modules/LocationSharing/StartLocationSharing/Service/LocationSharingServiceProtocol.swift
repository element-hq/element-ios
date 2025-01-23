//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import CoreLocation
import Foundation

/// Location authorization request handler
typealias LocationAuthorizationHandler = (_ authorizationStatus: LocationAuthorizationStatus) -> Void

protocol LocationSharingServiceProtocol {
    /// Request location authorization
    func requestAuthorization(_ handler: @escaping LocationAuthorizationHandler)
}
