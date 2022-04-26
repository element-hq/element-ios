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

@objcMembers
public class MockRoomSummary: NSObject, MXRoomSummaryProtocol {
    public var roomId: String
    
    public var roomTypeString: String?
    
    public var roomType: MXRoomType = .room
    
    public var avatar: String?
    
    public var displayname: String?
    
    public var topic: String?
    
    public var creatorUserId: String = "@room_creator:matrix.org"
    
    public var aliases: [String] = []
    
    public var joinRule: String? = kMXRoomJoinRuleInvite
    
    public var historyVisibility: String?
    
    public var membership: MXMembership = .join
    
    public var membershipTransitionState: MXMembershipTransitionState = .joined
    
    public var membersCount: MXRoomMembersCount = MXRoomMembersCount(members: 2, joined: 2, invited: 0)
    
    public var isConferenceUserRoom: Bool = false
    
    public var hiddenFromUser: Bool = false
    
    public var storedHash: UInt = 0
    
    public var lastMessage: MXRoomLastMessage?
    
    public var isEncrypted: Bool = false
    
    public var trust: MXUsersTrustLevelSummary?
    
    public var localUnreadEventCount: UInt = 0
    
    public var notificationCount: UInt = 0
    
    public var highlightCount: UInt = 0
    
    public var hasAnyUnread: Bool {
        return localUnreadEventCount > 0
    }
    
    public var hasAnyNotification: Bool {
        return notificationCount > 0
    }
    
    public var hasAnyHighlight: Bool {
        return highlightCount > 0
    }
    
    public var isDirect: Bool {
        return isTyped(.direct)
    }
    
    public var directUserId: String?
    
    public var others: [String: NSCoding]?
    
    public var favoriteTagOrder: String?
    
    public var dataTypes: MXRoomSummaryDataTypes = []
    
    public func isTyped(_ types: MXRoomSummaryDataTypes) -> Bool {
        return (dataTypes.rawValue & types.rawValue) != 0
    }
    
    public var sentStatus: MXRoomSummarySentStatus = .ok
    
    public var spaceChildInfo: MXSpaceChildInfo?
    
    public var parentSpaceIds: Set<String> = []
    
    public var beaconInfoEvents: [MXBeaconInfo] = []
    
    public var userIdsSharingLiveBeacon: Set<String> = []
    
    public init(withRoomId roomId: String) {
        self.roomId = roomId
        super.init()
    }
    
    public static func generate() -> MockRoomSummary {
        return generate(withTypes: [])
    }
    
    public static func generateDirect() -> MockRoomSummary {
        return generate(withTypes: .direct)
    }
    
    public static func generate(withTypes types: MXRoomSummaryDataTypes) -> MockRoomSummary {
        guard let random = MXTools.generateSecret() else {
            fatalError("Room id cannot be created")
        }
        let result = MockRoomSummary(withRoomId: "!\(random):matrix.org")
        result.dataTypes = types
        if types.contains(.invited) {
            result.membership = .invite
            result.membershipTransitionState = .invited
        }
        return result
    }
    
}
