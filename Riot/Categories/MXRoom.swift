// 
// Copyright 2025 New Vector Ltd
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

@objc
extension MXRoom {
    /// Returns true if the user is the last owner of the room, but not the last member.
    func isLastOwner() async throws -> Bool {
        let userID = mxSession.myUserId
        let state = try await state()
        
        let requiredPowerLevel: RoomPowerLevel = state.isMSC4289Supported() ? .owner : .admin
        
        guard state.powerLevelOfUser(withUserID: userID) >= requiredPowerLevel.rawValue else {
            return false
        }
        
        guard let joinedMembers = try await members()?.members(with: .join) else {
            return false
        }
        
        var areOtherMembers = false
        for member in joinedMembers where member.userId != userID {
            // User is not the last member in the whole room.
            areOtherMembers = true
            // If there are other owners/admins the user can leave
            if state.powerLevelOfUser(withUserID: member.userId) >= requiredPowerLevel.rawValue {
                return false
            }
        }
        return areOtherMembers
    }
}
