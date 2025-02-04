// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
