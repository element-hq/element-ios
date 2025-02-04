// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit
import Reusable
import Mapbox

class LocationMarkerView: MGLAnnotationView, NibLoadable {
    
    @IBOutlet private var backgroundImageView: UIImageView!
    @IBOutlet private var avatarView: UserAvatarView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    func setAvatarData(_ avatarData: AvatarViewDataProtocol, avatarBackgroundColor: UIColor) {
        backgroundImageView.image = Asset.Images.locationUserMarker.image
        backgroundImageView.tintColor = avatarBackgroundColor
        avatarView.fill(with: avatarData)
    }
}
