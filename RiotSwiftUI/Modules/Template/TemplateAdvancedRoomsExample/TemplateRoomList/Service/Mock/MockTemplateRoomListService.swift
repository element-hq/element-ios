//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
