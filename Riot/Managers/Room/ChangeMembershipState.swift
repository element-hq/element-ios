// 
// Copyright 2020 New Vector Ltd
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

/// `ChangeMembershipState` represents room membership change states
enum ChangeMembershipState {        
    case unknown
    case pending
    case joining
    case failedJoining(Error)
    case joined
    case leaving
    case failedLeaving(Error)
    case left
    
    func isInProgress() -> Bool {
        switch self {
        case .joining, .leaving:
            return true
        default:
            return false
        }
    }
    
    func isSuccessful() -> Bool {
        switch self {
        case .joined, .left:
            return true
        default:
            return false
        }
    }
    
    func isError() -> Bool {
        switch self {
        case .failedJoining, .failedLeaving:
            return true
        default:
            return false
        }
    }
}
