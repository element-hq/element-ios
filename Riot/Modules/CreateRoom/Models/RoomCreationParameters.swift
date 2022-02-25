// 
// Copyright 2020 New Vector Ltd
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
