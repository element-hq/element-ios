//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import CoreLocation
import Foundation

protocol LiveLocationSharingViewerServiceProtocol {
    /// All shared users live location
    var usersLiveLocation: [UserLiveLocation] { get }
    
    /// Called when users live location are updated (new location, location stopped, …).
    var didUpdateUsersLiveLocation: (([UserLiveLocation]) -> Void)? { get set }
    
    func isCurrentUserId(_ userId: String) -> Bool
    
    func startListeningLiveLocationUpdates()
    
    func stopListeningLiveLocationUpdates()
    
    /// Stop current user location sharing
    func stopUserLiveLocationSharing(completion: @escaping (Result<Void, Error>) -> Void)
    
    func requestAuthorizationIfNeeded() -> Bool
}
