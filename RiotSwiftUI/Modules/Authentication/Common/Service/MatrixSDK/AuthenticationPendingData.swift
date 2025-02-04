//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// This class holds all pending data when creating a session, either by login or by register
class AuthenticationPendingData {
    let homeserverAddress: String
    
    // MARK: - Common
    
    var clientSecret = UUID().uuidString
    var sendAttempt: UInt = 0
    
    // MARK: - For login
    
    // var resetPasswordData: ResetPasswordData?
    
    // MARK: - For registration
    
    var currentSession: String?
    var isRegistrationStarted = false
    var currentThreePIDData: ThreePIDData?
    
    // MARK: - Setup
    
    init(homeserverAddress: String) {
        self.homeserverAddress = homeserverAddress
    }
}
