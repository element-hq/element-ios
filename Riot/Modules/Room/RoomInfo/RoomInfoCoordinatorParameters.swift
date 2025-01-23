// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

@objc
enum RoomInfoSection: Int {
    case none
    case addParticipants
    case settings
    case changeAvatar
    case changeTopic
}

@objcMembers
class RoomInfoCoordinatorParameters: NSObject {
    
    let session: MXSession
    let room: MXRoom
    let parentSpaceId: String?
    let initialSection: RoomInfoSection
    let dismissOnCancel: Bool
    let canAddParticipants: Bool
    
    init(session: MXSession, room: MXRoom, parentSpaceId: String?, initialSection: RoomInfoSection, canAddParticipants: Bool = true, dismissOnCancel: Bool) {
        self.session = session
        self.room = room
        self.parentSpaceId = parentSpaceId
        self.initialSection = initialSection
        self.canAddParticipants = canAddParticipants
        self.dismissOnCancel = dismissOnCancel
        super.init()
    }
    
    convenience init(session: MXSession, room: MXRoom, parentSpaceId: String?) {
        self.init(session: session, room: room, parentSpaceId: parentSpaceId, initialSection: .none, dismissOnCancel: false)
    }
    
    convenience init(session: MXSession, room: MXRoom, parentSpaceId: String?, initialSection: RoomInfoSection) {
        self.init(session: session, room: room, parentSpaceId: parentSpaceId, initialSection: initialSection, dismissOnCancel: false)
    }

    convenience init(session: MXSession, room: MXRoom, parentSpaceId: String?, initialSection: RoomInfoSection, canAddParticipants: Bool) {
        self.init(session: session, room: room, parentSpaceId: parentSpaceId, initialSection: initialSection, canAddParticipants: canAddParticipants, dismissOnCancel: false)
    }
}
