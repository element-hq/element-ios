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


class FakeEvent: MXEvent {
    
    var mockEventId: String;
    var mockSender: String!;
    var mockDecryptionError: Error?
    
    init(id: String) {
        mockEventId = id
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }

    override var sender: String! {
        get { return mockSender }
        set { mockSender = newValue }
    }
    
    override var eventId: String! {
        get { return mockEventId }
        set { mockEventId = newValue }
    }
    
    override var decryptionError: Error? {
        get { return mockDecryptionError }
        set { mockDecryptionError = newValue }
    }
    
}


class FakeRoomState: MXRoomState {
    
    var mockMembers: MXRoomMembers?
    
    override var members: MXRoomMembers? {
        get { return mockMembers }
        set { mockMembers = newValue }
    }
    
}

class FakeRoomMember: MXRoomMember {
    var mockMembership: MXMembership = MXMembership.join
    var mockUserId: String!
    var mockMembers: MXRoomMembers? = FakeRoomMembers()
    
    init(mockUserId: String!) {
        self.mockUserId = mockUserId
        super.init()
    }
    
    override var membership: MXMembership {
        get { return mockMembership }
        set { mockMembership = newValue }
    }
    
    override var userId: String!{
        get { return mockUserId }
        set { mockUserId = newValue }
    }

}


class FakeRoomMembers: MXRoomMembers {
    
    var mockMembers = [String : MXMembership]()
    
    init(joined: [String] = [String]()) {
        for userId in joined {
            self.mockMembers[userId] = MXMembership.join
        }
        super.init()
    }
    
    override func member(withUserId userId: String!) -> MXRoomMember? {
        let membership = mockMembers[userId]
        if membership != nil {
            let mockMember = FakeRoomMember(mockUserId: userId)
            mockMember.mockMembership = membership!
            return mockMember
        } else {
            return nil
        }
    }
    
}
