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

/// `RoomChangeMembershipStateDataSource` store and notify room membership state change
@objcMembers
final class RoomChangeMembershipStateDataSource: NSObject {
    
    // MARK: - Notifications
    
    /// Posted when a membership state of a room is changed. The `Notification` contains the room id.
    static let didChangeRoomMembershipStateNotification = Notification.Name(rawValue: "RoomChangeMembershipStateDataSource.didChangeRoomMembershipState")
    
    /// The key in notification userInfo dictionary representating the roomId.
    static let notificationUserInfoRoomIdKey = "roomId"
    
    // MARK: - Properties
    
    private var changeMembershipStates: [String: ChangeMembershipState] = [:]
    
    // MARK: - Public
    
    func createOrUpdateStateIfNeeded(for roomId: String, and membership: MXMembership) -> ChangeMembershipState {
        let state: ChangeMembershipState
                
        if let currentState = self.getState(for: roomId) {
            state = currentState
        } else {
            state = self.changeMembershipState(for: membership)
        }
        
        self.changeMembershipStates[roomId] = state
        
        return state
    }
    
    func getState(for roomId: String) -> ChangeMembershipState? {
        self.changeMembershipStates[roomId]
    }
    
    func updateState(for roomId: String, from membership: MXMembership) {
        self.updateState(for: roomId, with: self.changeMembershipState(for: membership))
    }
    
    func updateState(for roomId: String, with changeMembershipState: ChangeMembershipState) {        
        self.changeMembershipStates[roomId] = changeMembershipState
        let userInfo = [RoomChangeMembershipStateDataSource.notificationUserInfoRoomIdKey: roomId]
        NotificationCenter.default.post(name: RoomChangeMembershipStateDataSource.didChangeRoomMembershipStateNotification, object: self, userInfo: userInfo)
    }
    
    // MARK: - Private
    
    private func changeMembershipState(for membership: MXMembership) -> ChangeMembershipState {
        
        let inviteState: ChangeMembershipState
        
        switch membership {
        case .invite:
            inviteState = .pending
        case .join:
            inviteState = .joined
        case .leave:
            inviteState = .left
        default:
            inviteState = .unknown
        }
        
        return inviteState
    }
}
