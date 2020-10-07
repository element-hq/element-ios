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
import ReadMoreTextView

class RoomInfoBasicView: UIView {
    
    private enum TopicTextViewConstants {
        static let font = UIFont.systemFont(ofSize: 15)
        static let defaultNumberOfLines = 4
        static let moreLessTextPadding = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
    }

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
    @IBOutlet private weak var topicContainerView: UIView!
    @IBOutlet private weak var topicTitleLabel: UILabel! {
        didSet {
            topicTitleLabel.text = VectorL10n.roomDetailsTopic
        }
    }
    @IBOutlet private weak var roomTopicTextView: ReadMoreTextView! {
        didSet {
            roomTopicTextView.contentInset = .zero
            roomTopicTextView.textContainerInset = .zero
            roomTopicTextView.textContainer.lineFragmentPadding = 0
            roomTopicTextView.readMoreTextPadding = TopicTextViewConstants.moreLessTextPadding
            roomTopicTextView.readLessTextPadding = TopicTextViewConstants.moreLessTextPadding
            roomTopicTextView.shouldTrim = true
            roomTopicTextView.maximumNumberOfLines = TopicTextViewConstants.defaultNumberOfLines
            roomTopicTextView.onSizeChange = { _ in
                self.roomTopicTextView.textAlignment = .left
                self.onTopicSizeChange?(self)
            }
        }
    }
    @IBOutlet private weak var securityContainerView: UIView!
    @IBOutlet private weak var securityTitleLabel: UILabel!
    @IBOutlet private weak var securityInformationLabel: UILabel!
    
    /// Block to be invoked when topic text view changes its content size.
    var onTopicSizeChange: ((RoomInfoBasicView) -> Void)?
    
    /// Force to update topic text view trimming.
    func updateTrimmingOnTopic() {
        roomTopicTextView.setNeedsUpdateTrim()
        let currentValue = roomTopicTextView.shouldTrim
        roomTopicTextView.shouldTrim = !currentValue
        roomTopicTextView.shouldTrim = currentValue
        roomTopicTextView.textAlignment = .left
    }
    
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
        roomTopicTextView.text = viewData.roomTopic
        topicContainerView.isHidden = roomTopicTextView.text?.isEmpty ?? true
        securityTitleLabel.text = VectorL10n.securitySettingsTitle
        securityInformationLabel.text = viewData.isDirect ?
            VectorL10n.roomParticipantsSecurityInformationRoomEncryptedForDm :
            VectorL10n.roomParticipantsSecurityInformationRoomEncrypted
        securityContainerView.isHidden = !viewData.isEncrypted
    }
    
}

extension RoomInfoBasicView: NibLoadable {}

extension RoomInfoBasicView: Themable {
    
    func update(theme: Theme) {
        backgroundColor = theme.headerBackgroundColor
        roomNameLabel.textColor = theme.textPrimaryColor
        roomAddressLabel.textColor = theme.textSecondaryColor
        topicTitleLabel.textColor = theme.textSecondaryColor
        roomTopicTextView.textColor = theme.textPrimaryColor
        roomTopicTextView.linkTextAttributes = [
            NSAttributedString.Key.font: TopicTextViewConstants.font,
            NSAttributedString.Key.foregroundColor: theme.tintColor
        ]
        let mutableReadMore = NSMutableAttributedString(string: "… ", attributes: [
            NSAttributedString.Key.font: TopicTextViewConstants.font,
            NSAttributedString.Key.foregroundColor: theme.textPrimaryColor
        ])
        let attributedMore = NSAttributedString(string: VectorL10n.more, attributes: [
            NSAttributedString.Key.font: TopicTextViewConstants.font,
            NSAttributedString.Key.foregroundColor: theme.tintColor
        ])
        mutableReadMore.append(attributedMore)
        roomTopicTextView.attributedReadMoreText = mutableReadMore
        
        let mutableReadLess = NSMutableAttributedString(string: " ")
        let attributedLess = NSAttributedString(string: VectorL10n.less, attributes: [
            NSAttributedString.Key.font: TopicTextViewConstants.font,
            NSAttributedString.Key.foregroundColor: theme.tintColor
        ])
        mutableReadLess.append(attributedLess)
        roomTopicTextView.attributedReadLessText = mutableReadLess
        
        securityTitleLabel.textColor = theme.textSecondaryColor
        securityInformationLabel.textColor = theme.textPrimaryColor
    }
    
}
