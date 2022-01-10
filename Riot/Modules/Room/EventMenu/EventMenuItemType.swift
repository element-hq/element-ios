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

/// Type of an event menu item. Ordering of the cases is important. See `EventMenuBuilder`.
@objc
enum EventMenuItemType: Int {
    case viewInRoom
    case copy
    case retrySending
    case cancelSending
    case cancelDownloading
    case saveMedia
    case quote
    case forward
    case permalink
    case share
    case removePoll
    case endPoll
    case reactionHistory
    case viewSource
    case viewDecryptedSource
    case viewEncryption
    case report
    case remove
    case cancel
}

extension EventMenuItemType: Comparable {
    
    static func < (lhs: EventMenuItemType, rhs: EventMenuItemType) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
}
