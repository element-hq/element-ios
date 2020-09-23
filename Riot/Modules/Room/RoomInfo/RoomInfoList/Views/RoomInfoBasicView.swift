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

import UIKit
import Reusable

class RoomInfoBasicView: UIView {

    @IBOutlet private weak var mainStackView: UIStackView!
    @IBOutlet private weak var avatarImageView: MXKImageView!
    @IBOutlet private weak var shadowView: UIView! {
        didSet {
            let shadowPath = UIBezierPath(roundedRect: shadowView.bounds, cornerRadius: 0)
            let layer = CALayer()
            layer.shadowPath = shadowPath.cgPath
            layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.12).cgColor
            layer.shadowOpacity = 1
            layer.shadowRadius = 25
            layer.shadowOffset = CGSize(width: 0, height: 4)
            layer.bounds = shadowView.bounds
            layer.position = shadowView.center

            shadowView.layer.addSublayer(layer)
        }
    }
    @IBOutlet private weak var badgeImageView: UIImageView!
    @IBOutlet private weak var roomNameLabel: UILabel!
    @IBOutlet private weak var roomAddressLabel: UILabel!
    @IBOutlet private weak var roomTopicLabel: UILabel!
    
    func configure(withViewData viewData: RoomInfoBasicViewData) {
        let avatarImage = AvatarGenerator.generateAvatar(forMatrixItem: viewData.roomId, withDisplayName: viewData.roomDisplayName)
        
        if let avatarUrl = viewData.avatarUrl {
            avatarImageView.enableInMemoryCache = true

            avatarImageView.setImageURI(avatarUrl,
                                        withType: nil,
                                        andImageOrientation: .up,
                                        toFitViewSize: avatarImageView.frame.size,
                                        with: MXThumbnailingMethodCrop,
                                        previewImage: avatarImage,
                                        mediaManager: viewData.mediaManager)
        } else {
            avatarImageView.image = avatarImage
        }
        badgeImageView.image = viewData.encryptionImage
        roomNameLabel.text = viewData.roomDisplayName
        roomAddressLabel.text = viewData.mainRoomAlias
        roomAddressLabel.isHidden = roomAddressLabel.text?.isEmpty ?? true
        roomTopicLabel.text = viewData.roomTopic
        roomTopicLabel.isHidden = roomTopicLabel.text?.isEmpty ?? true
    }

}

extension RoomInfoBasicView: NibLoadable {}

extension RoomInfoBasicView: Themable {
    
    func update(theme: Theme) {
        backgroundColor = theme.headerBackgroundColor
        roomNameLabel.textColor = theme.textPrimaryColor
        roomAddressLabel.textColor = theme.textSecondaryColor
        roomTopicLabel.textColor = theme.textSecondaryColor
    }
    
}
