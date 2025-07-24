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
        
        guard RoomPowerLevelHelper.roomPowerLevel(from: state.powerLevelOfUser(withUserID: userID)) == .owner else {
            return false
        }
        
        guard let joinedMembers = try await members()?.members(with: .join) else {
            return false
        }
        
        var isLastMember = true
        for member in joinedMembers where member.userId != userID {
            isLastMember = false
            // If there are other owners they can leave
            if RoomPowerLevelHelper.roomPowerLevel(from: state.powerLevelOfUser(withUserID: member.userId)) == .owner {
                return false
            }
        }
        return !isLastMember
    }
}
