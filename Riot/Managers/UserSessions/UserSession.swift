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
