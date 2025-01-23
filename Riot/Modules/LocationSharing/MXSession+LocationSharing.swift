// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixSDK

extension MXSession {
    
    /// Convenient getter to retrieve UserLocationService associated to session user id
    var userLocationService: UserLocationServiceProtocol? {
        guard let myUserId = self.myUserId else {
            return nil
        }
        
        return UserLocationServiceProvider.shared.locationService(for: myUserId)
    }
}
