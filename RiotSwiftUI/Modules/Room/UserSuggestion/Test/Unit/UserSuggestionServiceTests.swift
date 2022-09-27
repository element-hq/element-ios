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

import Combine
import XCTest

@testable import RiotSwiftUI

class UserSuggestionServiceTests: XCTestCase {
    var service: UserSuggestionService?
    
    override func setUp() {
        service = UserSuggestionService(roomMemberProvider: self, shouldDebounce: false)
    }
    
    func testAlice() {
        service?.processTextMessage("@Al")
        assert(service?.items.value.first?.displayName == "Alice")
        
        service?.processTextMessage("@al")
        assert(service?.items.value.first?.displayName == "Alice")
        
        service?.processTextMessage("@ice")
        assert(service?.items.value.first?.displayName == "Alice")
        
        service?.processTextMessage("@Alice")
        assert(service?.items.value.first?.displayName == "Alice")
        
        service?.processTextMessage("@alice:matrix.org")
        assert(service?.items.value.first?.displayName == "Alice")
    }
    
    func testBob() {
        service?.processTextMessage("@ob")
        assert(service?.items.value.first?.displayName == "Bob")
        
        service?.processTextMessage("@ob:")
        assert(service?.items.value.first?.displayName == "Bob")
        
        service?.processTextMessage("@b:matrix")
        assert(service?.items.value.first?.displayName == "Bob")
    }
    
    func testBoth() {
        service?.processTextMessage("@:matrix")
        assert(service?.items.value.first?.displayName == "Alice")
        assert(service?.items.value.last?.displayName == "Bob")
        
        service?.processTextMessage("@.org")
        assert(service?.items.value.first?.displayName == "Alice")
        assert(service?.items.value.last?.displayName == "Bob")
    }
    
    func testEmptyResult() {
        service?.processTextMessage("Lorem ipsum idolor")
        assert(service?.items.value.count == 0)
        
        service?.processTextMessage("@")
        assert(service?.items.value.count == 0)
        
        service?.processTextMessage("@@")
        assert(service?.items.value.count == 0)
        
        service?.processTextMessage("alice@matrix.org")
        assert(service?.items.value.count == 0)
    }
    
    func testStuff() {
        service?.processTextMessage("@@")
        assert(service?.items.value.count == 0)
    }
    
    func testWhitespaces() {
        service?.processTextMessage("")
        assert(service?.items.value.count == 0)
        
        service?.processTextMessage(" ")
        assert(service?.items.value.count == 0)
        
        service?.processTextMessage("\n")
        assert(service?.items.value.count == 0)
        
        service?.processTextMessage(" \n ")
        assert(service?.items.value.count == 0)
        
        service?.processTextMessage("@A   ")
        assert(service?.items.value.count == 0)
        
        service?.processTextMessage("  @A   ")
        assert(service?.items.value.count == 0)
    }
}

extension UserSuggestionServiceTests: RoomMembersProviderProtocol {
    func fetchMembers(_ members: @escaping ([RoomMembersProviderMember]) -> Void) {
        let users = [("Alice", "@alice:matrix.org"),
                     ("Bob", "@bob:matrix.org")]
        
        members(users.map { user in
            RoomMembersProviderMember(userId: user.1, displayName: user.0, avatarUrl: "")
        })
    }
}
