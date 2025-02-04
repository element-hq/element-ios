//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

class TemplateRoomListService: TemplateRoomListServiceProtocol {
    private let session: MXSession
    private var listenerReference: Any?

    private(set) var roomsSubject: CurrentValueSubject<[TemplateRoomListRoom], Never>
    
    init(session: MXSession) {
        self.session = session
        
        let unencryptedRooms = session.rooms
            .filter { !$0.summary.isEncrypted }
            .map(TemplateRoomListRoom.init(mxRoom:))
        roomsSubject = CurrentValueSubject(unencryptedRooms)
    }
}

private extension TemplateRoomListRoom {
    init(mxRoom: MXRoom) {
        self.init(id: mxRoom.roomId, avatar: mxRoom.avatarData, displayName: mxRoom.summary.displayName)
    }
}
