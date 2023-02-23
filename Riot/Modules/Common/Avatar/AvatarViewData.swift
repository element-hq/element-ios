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

struct AvatarViewData: AvatarViewDataProtocol {
    /// Matrix item identifier (user id or room id)
    var matrixItemId: String
    
    /// Matrix item display name (user or room display name)
    var displayName: String?

    /// Matrix item avatar URL (user or room avatar url)
    var avatarUrl: String?
        
    /// Matrix media handler if exists
    var mediaManager: MXMediaManager?
    
    /// Fallback images used when avatarUrl is nil
    var fallbackImages: [AvatarFallbackImage]?
}

extension AvatarViewData {
    init(matrixItemId: String,
         displayName: String? = nil,
         avatarUrl: String? = nil,
         mediaManager: MXMediaManager? = nil,
         fallbackImage: AvatarFallbackImage?) {
        
        self.matrixItemId = matrixItemId
        self.displayName = displayName
        self.avatarUrl = avatarUrl
        self.mediaManager = mediaManager
        self.fallbackImages = fallbackImage.map { [$0] }
    }
}
