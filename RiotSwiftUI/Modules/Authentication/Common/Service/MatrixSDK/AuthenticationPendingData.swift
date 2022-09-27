//
// Copyright 2022 New Vector Ltd
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
