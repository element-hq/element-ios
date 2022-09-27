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
}
