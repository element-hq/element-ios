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
import UIKit

class SpaceCreationParameters {
    var name: String?
    var topic: String?
    var address: String?
    var userDefinedAddress: String?
    var isPublic: Bool = false
    var showAddress: Bool {
        isPublic
    }
    
    var userSelectedAvatar: UIImage?
    var isShared: Bool = false
    
    var newRooms: [SpaceCreationNewRoom] = [
        SpaceCreationNewRoom(name: VectorL10n.spacesCreationNewRoomsGeneral, defaultName: VectorL10n.spacesCreationNewRoomsGeneral),
        SpaceCreationNewRoom(name: VectorL10n.spacesCreationNewRoomsRandom, defaultName: VectorL10n.spacesCreationNewRoomsRandom),
        SpaceCreationNewRoom(name: "", defaultName: VectorL10n.spacesCreationNewRoomsSupport)
    ]
    var addedRoomIds: [String] = []

    var emailInvites: [String] = ["", ""]
    var userDefinedEmailInvites: [String] {
        return emailInvites.filter { address in
            return !address.isEmpty
        }
    }
    var userIdInvites: [String] = []
}

struct SpaceCreationNewRoom: Equatable {
    var name: String
    var defaultName: String
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.defaultName == rhs.defaultName && lhs.name == rhs.name
    }
}
