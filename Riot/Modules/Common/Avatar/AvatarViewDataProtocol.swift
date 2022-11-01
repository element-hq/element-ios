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

import UIKit

enum AvatarFallbackImage {
    
    /// matrixItem represent a Matrix item like a room, space, user
    /// matrixItemId: Matrix item identifier (user id or room id)
    /// displayName: Matrix item display name (user or room display name)
    case matrixItem(_ matrixItemId: String, _ displayName: String?)
    
    /// Normal image with optional content mode
    case image(_ image: UIImage, _ contentMode: UIView.ContentMode? = nil)
}

/// AvatarViewDataProtocol describe a view data that should be given to an AvatarView sublcass
protocol AvatarViewDataProtocol: AvatarProtocol {
    /// Matrix item identifier (user id or room id)
    var matrixItemId: String { get }
    
    /// Matrix item display name (user or room display name)
    var displayName: String? { get }
    
    /// Matrix item avatar URL (user or room avatar url)
    var avatarUrl: String? { get }            
        
    /// Matrix media handler
    var mediaManager: MXMediaManager? { get }
    
    /// Fallback images used when avatarUrl is nil
    var fallbackImages: [AvatarFallbackImage]? { get }
}

extension AvatarViewDataProtocol {
    func fallbackImageParameters() -> (UIImage?, UIView.ContentMode)? {
        fallbackImages?
            .lazy
            .map { fallbackImage in
                switch fallbackImage {
                case .matrixItem(let matrixItemId, let matrixItemDisplayName):
                    return (AvatarGenerator.generateAvatar(forMatrixItem: matrixItemId, withDisplayName: matrixItemDisplayName), .scaleAspectFill)
                case .image(let image, let contentMode):
                    return (image, contentMode ?? .scaleAspectFill)
                }
            }
            .first { (image, contentMode) in
                image != nil
            }
    }
}
