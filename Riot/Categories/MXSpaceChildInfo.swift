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

extension MXSpaceChildInfo {
    func setRoomAvatarImage(in mxkImageView: MXKImageView, mediaManager: MXMediaManager) {
        // Use the room display name to prepare the default avatar image.
        let avatarDisplayName = self.name
        let avatarImage = AvatarGenerator.generateAvatar(forText: avatarDisplayName)
        
        if let avatarUrl = self.avatarUrl {
            mxkImageView.enableInMemoryCache = true
            mxkImageView.setImageURI(avatarUrl, withType: nil, andImageOrientation: .up, toFitViewSize: mxkImageView.frame.size, with: MXThumbnailingMethodCrop, previewImage: avatarImage, mediaManager: mediaManager)
        } else {
            mxkImageView.image = avatarImage
        }
        mxkImageView.contentMode = .scaleAspectFill
    }
}
