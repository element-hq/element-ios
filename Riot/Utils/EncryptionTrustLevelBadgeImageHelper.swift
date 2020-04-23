/*
 Copyright 2020 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import UIKit

@objcMembers
final class EncryptionTrustLevelBadgeImageHelper: NSObject {
    
    static func roomBadgeImage(for trustLevel: RoomEncryptionTrustLevel) -> UIImage {
        
        let badgeImage: UIImage
        
        switch trustLevel {
        case .warning:
            badgeImage = Asset.Images.encryptionWarning.image
        case .normal:
            badgeImage = Asset.Images.encryptionNormal.image
        case .trusted:
            badgeImage = Asset.Images.encryptionTrusted.image
        case .unknown:
            badgeImage = Asset.Images.encryptionNormal.image
        @unknown default:
            badgeImage = Asset.Images.encryptionNormal.image
        }
        
        return badgeImage
    }
    
    static func userBadgeImage(for trustLevel: UserEncryptionTrustLevel) -> UIImage? {
        
        let badgeImage: UIImage?
        
        switch trustLevel {
        case .warning:
            badgeImage = Asset.Images.encryptionWarning.image
        case .notVerified, .noCrossSigning:
            badgeImage = Asset.Images.encryptionNormal.image
        case .trusted:
            badgeImage = Asset.Images.encryptionTrusted.image
        default:
            badgeImage = nil
        }
        
        return badgeImage
    }
}
