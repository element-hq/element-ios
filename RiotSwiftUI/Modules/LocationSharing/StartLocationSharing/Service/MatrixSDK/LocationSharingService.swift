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

import CoreLocation
import Foundation
import MatrixSDK

class LocationSharingService: LocationSharingServiceProtocol {
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    
    private var userLocationService: UserLocationServiceProtocol? {
        session.userLocationService
    }
    
    // MARK: Public
    
    // MARK: - Setup
    
    init(session: MXSession) {
        self.session = session
    }
    
    // MARK: - Public
    
    func requestAuthorization(_ handler: @escaping LocationAuthorizationHandler) {
        guard let userLocationService = userLocationService else {
            MXLog.error("[LocationSharingService] No userLocationService found for the current session")
            handler(LocationAuthorizationStatus.unknown)
            return
        }
        
        userLocationService.requestAuthorization(handler)
    }
}
