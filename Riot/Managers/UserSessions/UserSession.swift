// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// UserSessionProtocol represents a user session regardless of the communication protocol
protocol UserSessionProtocol {
    var userId: String { get }
}

/// UserSession represents a Matrix user session
/// Note: UserSessionProtocol can be renamed UserSession and UserSession -> MatrixUserSession if we keep this abstraction.
@objcMembers
class UserSession: NSObject, UserSessionProtocol {
        
    // MARK: - Properties
    
    // MARK: Public
    
    let account: MXKAccount
    // Keep strong reference to the MXSession because account.mxSession can become nil on logout or failure
    let matrixSession: MXSession
    let userId: String
    /// An object that contains user specific properties.
    let userProperties: UserSessionProperties
    
    // MARK: - Setup
    
    init(account: MXKAccount, matrixSession: MXSession) {
        guard let userId = account.mxCredentials.userId else {
            fatalError("[UserSession] identifier: account.mxCredentials.userId should be defined")
        }
        
        self.account = account
        self.matrixSession = matrixSession
        self.userId = userId
        self.userProperties = UserSessionProperties(userId: userId)
        super.init()
    }
}
