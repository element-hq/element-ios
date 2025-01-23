// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

struct RoomCreationParameters {
    var name: String?
    var topic: String?
    var address: String?
    var avatarImage: UIImage? {
        return userSelectedAvatar
    }
    var isEncrypted: Bool = false
    var joinRule: MXRoomJoinRule = .private {
        didSet {
            switch joinRule {
            case .restricted:
                showInDirectory = false
                address = nil
            case .private:
                showInDirectory = false
                address = nil
                isRoomSuggested = false
            default: break
            }
        }
    }
    var showInDirectory: Bool = false
    var isRoomSuggested: Bool = false
    
    var userSelectedAvatar: UIImage?
}
