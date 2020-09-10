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

struct DirectoryRoomTableViewCellVM {
    private let room: MXPublicRoom
    private let session: MXSession
    
    var title: String? {
        return room.displayname()
    }
    var numberOfUsers: Int {
        return room.numJoinedMembers
    }
    var subtitle: String? {
        guard let topic = room.topic else { return nil }
        return MXTools.stripNewlineCharacters(topic)
    }
    var isJoined: Bool {
        guard let summary = session.roomSummary(withRoomId: room.roomId) else {
            return false
        }
        return summary.membership == .join
    }

    func setAvatar(in avatarImageView: MXKImageView) {
        let avatarImage = AvatarGenerator.generateAvatar(forMatrixItem: room.roomId, withDisplayName: title)
        
        if let avatarUrl = room.avatarUrl {
            avatarImageView.enableInMemoryCache = true

            avatarImageView.setImageURI(avatarUrl,
                                        withType: nil,
                                        andImageOrientation: .up,
                                        toFitViewSize: avatarImageView.frame.size,
                                        with: MXThumbnailingMethodCrop,
                                        previewImage: avatarImage,
                                        mediaManager: session.mediaManager)
        } else {
            avatarImageView.image = avatarImage
        }
    }
    
    init(room: MXPublicRoom, session: MXSession) {
        self.room = room
        self.session = session
    }
}
