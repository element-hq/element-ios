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
    var title: String?
    var numberOfUsers: Int
    var subtitle: String?
    var isJoined: Bool = false
    
    private var roomId: String!
    private var avatarUrl: String?
    private var mediaManager: MXMediaManager?

    func setAvatar(in avatarImageView: MXKImageView) {
        let avatarImage = AvatarGenerator.generateAvatar(forMatrixItem: roomId, withDisplayName: title)
        
        if let avatarUrl = avatarUrl {
            avatarImageView.enableInMemoryCache = true

            avatarImageView.setImageURI(avatarUrl,
                                        withType: nil,
                                        andImageOrientation: .up,
                                        toFitViewSize: avatarImageView.frame.size,
                                        with: MXThumbnailingMethodCrop,
                                        previewImage: avatarImage,
                                        mediaManager: mediaManager)
        } else {
            avatarImageView.image = avatarImage
        }
    }
    
    /// Initializer declared explicitly due to private variables
    init(title: String?,
         numberOfUsers: Int,
         subtitle: String?,
         isJoined: Bool,
         roomId: String!,
         avatarUrl: String?,
         mediaManager: MXMediaManager?) {
        self.title = title
        self.numberOfUsers = numberOfUsers
        self.subtitle = subtitle
        self.isJoined = isJoined
        self.roomId = roomId
        self.avatarUrl = avatarUrl
        self.mediaManager = mediaManager
    }
}
