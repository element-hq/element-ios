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

struct RoomInfoBasicViewData {
    let avatarUrl: String?
    let mediaManager: MXMediaManager?
    
    let roomId: String
    let roomDisplayName: String?
    let mainRoomAlias: String?
    let roomTopic: String?
    let encryptionImage: UIImage?
    let isEncrypted: Bool
    let isDirect: Bool
    let directUserId: String?
    let directUserPresence: MXPresence
}
