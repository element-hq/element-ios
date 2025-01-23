//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import UIKit

enum SpaceCreationInviteType {
    case email
    case userId
}

class SpaceCreationParameters {
    var name: String? {
        didSet {
            isModified = true
        }
    }

    var topic: String? {
        didSet {
            isModified = true
        }
    }

    var address: String? {
        didSet {
            isModified = true
        }
    }

    var userDefinedAddress: String? {
        didSet {
            isModified = true
        }
    }

    var isPublic = false {
        didSet {
            isModified = true
        }
    }

    var showAddress: Bool {
        isPublic
    }
    
    var userSelectedAvatar: UIImage? {
        didSet {
            isModified = true
        }
    }

    var isShared = false {
        didSet {
            isModified = true
        }
    }
    
    var newRooms: [SpaceCreationNewRoom] = [
        SpaceCreationNewRoom(name: VectorL10n.spacesCreationNewRoomsGeneral, defaultName: VectorL10n.spacesCreationNewRoomsGeneral),
        SpaceCreationNewRoom(name: VectorL10n.spacesCreationNewRoomsRandom, defaultName: VectorL10n.spacesCreationNewRoomsRandom),
        SpaceCreationNewRoom(name: "", defaultName: VectorL10n.spacesCreationNewRoomsSupport)
    ] {
        didSet {
            isModified = true
        }
    }
    
    var addedRoomIds: [String]? {
        didSet {
            isModified = true
        }
    }

    var emailInvites: [String] = ["", ""] {
        didSet {
            isModified = true
        }
    }

    var userDefinedEmailInvites: [String] {
        emailInvites.filter { address in
            !address.isEmpty
        }
    }

    var userIdInvites: [String] = [] {
        didSet {
            isModified = true
        }
    }

    var inviteType: SpaceCreationInviteType = .email {
        didSet {
            isModified = true
        }
    }

    var isModified = false
}

struct SpaceCreationNewRoom: Equatable {
    var name: String
    var defaultName: String
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.defaultName == rhs.defaultName && lhs.name == rhs.name
    }
}
