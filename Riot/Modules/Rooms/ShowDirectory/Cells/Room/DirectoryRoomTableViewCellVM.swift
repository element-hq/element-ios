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
        
    let title: String?
    let numberOfUsers: Int
    let subtitle: String?
    let isJoined: Bool
    let roomId: String
    let avatarViewData: AvatarViewDataProtocol

    // TODO: Use AvatarView subclass in the cell view
    func setAvatar(in avatarImageView: MXKImageView) {
        let (defaultAvatarImage, defaultAvatarImageContentMode) = avatarViewData.fallbackImageParameters() ?? (nil, .scaleAspectFill)
        
        if let avatarUrl = self.avatarViewData.avatarUrl {
            avatarImageView.enableInMemoryCache = true

            avatarImageView.setImageURI(avatarUrl,
                                        withType: nil,
                                        andImageOrientation: .up,
                                        toFitViewSize: avatarImageView.frame.size,
                                        with: MXThumbnailingMethodCrop,
                                        previewImage: defaultAvatarImage,
                                        mediaManager: self.avatarViewData.mediaManager)
            avatarImageView.contentMode = .scaleAspectFill
        } else {
            avatarImageView.image = defaultAvatarImage
            avatarImageView.contentMode = defaultAvatarImageContentMode
        }
    }
    
    /// Initializer declared explicitly due to private variables
    init(title: String?,
         numberOfUsers: Int,
         subtitle: String?,
         isJoined: Bool = false,
         roomId: String!,
         avatarUrl: String?,
         mediaManager: MXMediaManager) {
        self.title = title
        self.numberOfUsers = numberOfUsers
        self.subtitle = subtitle
        self.isJoined = isJoined
        self.roomId = roomId
        
        let avatarViewData = RoomAvatarViewData(roomId: roomId, displayName: title, avatarUrl: avatarUrl, mediaManager: mediaManager)
        
        self.avatarViewData = avatarViewData
    }
}
