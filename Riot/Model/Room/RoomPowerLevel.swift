/*
Copyright 2020-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
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
