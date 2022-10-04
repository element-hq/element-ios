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
import Foundation

class MockTemplateRoomListService: TemplateRoomListServiceProtocol {
    static let mockRooms = [
        TemplateRoomListRoom(id: "!aaabaa:matrix.org", avatar: MockAvatarInput.example, displayName: "Matrix Discussion"),
        TemplateRoomListRoom(id: "!zzasds:matrix.org", avatar: MockAvatarInput.example, displayName: "Element Mobile"),
        TemplateRoomListRoom(id: "!scthve:matrix.org", avatar: MockAvatarInput.example, displayName: "Alice Personal")
    ]
    var roomsSubject: CurrentValueSubject<[TemplateRoomListRoom], Never>

    init(rooms: [TemplateRoomListRoom] = mockRooms) {
        roomsSubject = CurrentValueSubject(rooms)
    }
    
    func simulateUpdate(rooms: [TemplateRoomListRoom]) {
        roomsSubject.send(rooms)
    }
}
