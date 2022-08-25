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

extension MXKImageView {
    @objc func vc_setRoomAvatarImage(with url: String?, roomId: String, displayName: String, mediaManager: MXMediaManager) {
        // Use the display name to prepare the default avatar image.
        let avatarImage = AvatarGenerator.generateAvatar(forMatrixItem: roomId, withDisplayName: displayName)

        if let avatarUrl = url {
            enableInMemoryCache = true
            setImageURI(avatarUrl, withType: nil, andImageOrientation: .up, toFitViewSize: frame.size, with: MXThumbnailingMethodCrop, previewImage: avatarImage, mediaManager: mediaManager)
        } else {
            image = avatarImage
        }
        contentMode = .scaleAspectFill
    }
}
