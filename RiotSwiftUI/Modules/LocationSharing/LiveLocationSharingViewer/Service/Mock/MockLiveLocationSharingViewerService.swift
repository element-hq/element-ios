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

class MockLiveLocationSharingViewerService: LiveLocationSharingViewerServiceProtocol {
    // MARK: Properties
    
    private(set) var usersLiveLocation: [UserLiveLocation] = []
    
    var didUpdateUsersLiveLocation: (([UserLiveLocation]) -> Void)?
    
    // MARK: Setup
    
    init(generateRandomUsers: Bool = false, currentUserSharingLocation: Bool = true) {
        let firstUserLiveLocation: UserLiveLocation?
        if currentUserSharingLocation {
            firstUserLiveLocation = createFirstUserLiveLocation()
        } else {
            firstUserLiveLocation = nil
        }
        
        let secondUserLiveLocation = createSecondUserLiveLocation()
        
        var usersLiveLocation: [UserLiveLocation] = [firstUserLiveLocation, secondUserLiveLocation].compactMap { $0 }
        
        if generateRandomUsers {
            for _ in 1...20 {
                let randomUser = createRandomUserLiveLocation()
                usersLiveLocation.append(randomUser)
            }
        }

        self.usersLiveLocation = usersLiveLocation
    }
    
    // MARK: Public
    
    func isCurrentUserId(_ userId: String) -> Bool {
        userId == "@alice:matrix.org"
    }
    
    func startListeningLiveLocationUpdates() { }
    
    func stopListeningLiveLocationUpdates() { }
    
    func stopUserLiveLocationSharing(completion: @escaping (Result<Void, Error>) -> Void) { }
    
    func requestAuthorizationIfNeeded() -> Bool {
        return true
    }
    
    // MARK: Private
    
    private func createFirstUserLiveLocation() -> UserLiveLocation {
        let userAvatarData = AvatarInput(mxContentUri: nil, matrixItemId: "@alice:matrix.org", displayName: "Alice")
        let userCoordinate = CLLocationCoordinate2D(latitude: 51.4932641, longitude: -0.257096)
        
        let currentTimeInterval = Date().timeIntervalSince1970
        let timestamp = currentTimeInterval - 300
        let timeout: TimeInterval = 800
        let lastUpdate = currentTimeInterval - 100
        
        return UserLiveLocation(avatarData: userAvatarData, timestamp: timestamp, timeout: timeout, lastUpdate: lastUpdate, coordinate: userCoordinate)
    }
    
    private func createSecondUserLiveLocation() -> UserLiveLocation {
        let userAvatarData = AvatarInput(mxContentUri: nil, matrixItemId: "@bob:matrix.org", displayName: "Bob")
        let coordinate = CLLocationCoordinate2D(latitude: 51.4952641, longitude: -0.259096)
        
        let currentTimeInterval = Date().timeIntervalSince1970
        
        let timestamp = currentTimeInterval - 600
        let timeout: TimeInterval = 1200
        let lastUpdate = currentTimeInterval - 300
        
        return UserLiveLocation(avatarData: userAvatarData, timestamp: timestamp, timeout: timeout, lastUpdate: lastUpdate, coordinate: coordinate)
    }
    
    private func createRandomUserLiveLocation() -> UserLiveLocation {
        let uuidString = UUID().uuidString.suffix(8)
        
        let random = Double.random(in: 0.005...0.010)
        
        let userAvatarData = AvatarInput(mxContentUri: nil, matrixItemId: "@user_\(uuidString):matrix.org", displayName: "User \(uuidString)")
        let coordinate = CLLocationCoordinate2D(latitude: 51.4952641 + random, longitude: -0.259096 + random)
        
        let currentTimeInterval = Date().timeIntervalSince1970
        
        let timestamp = currentTimeInterval - 600
        let timeout: TimeInterval = 1200
        let lastUpdate = currentTimeInterval - 300
        
        return UserLiveLocation(avatarData: userAvatarData, timestamp: timestamp, timeout: timeout, lastUpdate: lastUpdate, coordinate: coordinate)
    }
}
