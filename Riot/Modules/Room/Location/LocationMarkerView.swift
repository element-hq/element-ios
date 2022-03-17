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
import Reusable
import Mapbox

class LocationMarkerView: MGLAnnotationView, NibLoadable {
    
    @IBOutlet private var markerBackground: UIImageView!
    @IBOutlet private var avatarView: UserAvatarView!
    
    private static var usernameColorGenerator = UserNameColorGenerator()
    private let theme: Theme = ThemeService.shared().theme
    
    override func awakeFromNib() {
        super.awakeFromNib()
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    func setAvatarData(_ avatarData: AvatarViewDataProtocol) {
        Self.usernameColorGenerator.defaultColor = theme.colors.primaryContent
        Self.usernameColorGenerator.userNameColors = theme.colors.namesAndAvatars
        let image = Asset.Images.locationUserMarker.image.withRenderingMode(.alwaysTemplate)
        markerBackground.image = image
        markerBackground.tintColor = Self.usernameColorGenerator.color(from: avatarData.matrixItemId)
        avatarView.fill(with: avatarData)
    }
}
