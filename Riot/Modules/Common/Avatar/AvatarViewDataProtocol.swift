// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
