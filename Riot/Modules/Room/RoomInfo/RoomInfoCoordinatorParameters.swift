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
    
    init(session: MXSession, room: MXRoom, parentSpaceId: String?, initialSection: RoomInfoSection, dismissOnCancel: Bool) {
        self.session = session
        self.room = room
        self.parentSpaceId = parentSpaceId
        self.initialSection = initialSection
        self.dismissOnCancel = dismissOnCancel
        super.init()
    }
    
    convenience init(session: MXSession, room: MXRoom, parentSpaceId: String?) {
        self.init(session: session, room: room, parentSpaceId: parentSpaceId, initialSection: .none, dismissOnCancel: false)
    }
    
    convenience init(session: MXSession, room: MXRoom, parentSpaceId: String?, initialSection: RoomInfoSection) {
        self.init(session: session, room: room, parentSpaceId: parentSpaceId, initialSection: initialSection, dismissOnCancel: false)
    }
}
