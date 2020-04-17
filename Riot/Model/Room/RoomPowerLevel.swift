/*
 Copyright 2020 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import Foundation

/// Riot Standard Room Member Power Level
@objc
public enum RoomPowerLevel: Int {
    case admin = 100
    case moderator = 50
    case user = 0
    
    public init?(rawValue: Int) {
        switch rawValue {
        case 100...:
            self = .admin
        case 50...99:
            self = .moderator
        default:
            self = .user
        }
    }
}

@objcMembers
public final class RoomPowerLevelHelper: NSObject {
    
    static func roomPowerLevel(from rawValue: Int) -> RoomPowerLevel {
        return RoomPowerLevel(rawValue: rawValue) ?? .user
    }
}
