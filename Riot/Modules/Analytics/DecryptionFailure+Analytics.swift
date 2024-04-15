// 
// Copyright 2024 New Vector Ltd
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
import AnalyticsEvents

extension DecryptionFailure {
    
    public func toAnalyticsEvent() -> AnalyticsEvent.Error {
        
        let timeToDecryptMillis: Int = if let ttd = self.timeToDecrypt {
            Int(ttd * 1000)
        } else {
            -1
        }
        
        let isHistoricalEvent = if let localAge = self.eventLocalAgeMillis {
            localAge < 0
        } else { false }
        
        let errorName = if isHistoricalEvent && self.trustOwnIdentityAtTimeOfFailure == false {
            AnalyticsEvent.Error.Name.HistoricalMessage
        } else {
            self.reason.errorName
        }
        
        return AnalyticsEvent.Error(
            context: self.context,
            cryptoModule: .Rust,
            cryptoSDK: .Rust,
            domain: .E2EE,
            eventLocalAgeMillis: self.eventLocalAgeMillis,
            isFederated: self.isFederated,
            isMatrixDotOrg: self.isMatrixOrg,
            name: errorName,
            timeToDecryptMillis: timeToDecryptMillis,
            userTrustsOwnIdentity: self.trustOwnIdentityAtTimeOfFailure,
            wasVisibleToUser: self.wasVisibleToUser
        )
    }
}
