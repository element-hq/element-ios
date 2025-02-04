//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
