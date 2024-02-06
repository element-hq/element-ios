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
    @IBOutlet private weak var avatarContainerView: UIView!
    @IBOutlet private weak var avatarImageView: MXKImageView!
    @IBOutlet private weak var badgeImageView: UIImageView!
    @IBOutlet private weak var presenceIndicatorView: PresenceIndicatorView! {
        didSet {
            presenceIndicatorView.delegate = self
        }
    }
    @IBOutlet private weak var roomNameStackView: UIStackView!
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
        var cleanedImg = viewData.roomDisplayName

        // Replace [TG] with an image
        if let tgRange = cleanedImg?.range(of: "[TG] ") {
            cleanedImg?.replaceSubrange(tgRange, with: "")
        }

        // Replace $ with a second image
        if let dollarRange = cleanedImg?.range(of: "$") {
            cleanedImg?.replaceSubrange(dollarRange, with: "")
        }
        let avatarImage = AvatarGenerator.generateAvatar(forMatrixItem: viewData.roomId, withDisplayName: cleanedImg)
        
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
        let attributedString = NSMutableAttributedString(string: viewData.roomDisplayName!)
        // Replace [TG] with an image
        if let range = viewData.roomDisplayName!.range(of: "[TG] ") {
            let imageAttachment = NSTextAttachment()
            imageAttachment.image = UIImage(named: "chatimg")
            
            // Adjust the bounds and baselineOffset for proper alignment
            let imageSize = imageAttachment.image?.size ?? CGSize(width: 20, height: 20) // Set a default size if the image is not available
            let yOffset = (roomNameLabel.font.capHeight - imageSize.height) / 2.0
            imageAttachment.bounds = CGRect(x: 0, y: yOffset, width: imageSize.width, height: imageSize.height)
            
            let imageString = NSAttributedString(attachment: imageAttachment)
            
            // Add a space after the image
            let spaceString = NSAttributedString(string: " ")
            
            // Combine image and space
            let combinedString = NSMutableAttributedString()
            combinedString.append(imageString)
            combinedString.append(spaceString)
            
            attributedString.replaceCharacters(in: NSRange(range, in: viewData.roomDisplayName!), with: combinedString)
        }

        // Replace $ with an image, only if [TG] is not present at the beginning
        if !viewData.roomDisplayName!.hasPrefix("[TG]"), let range = viewData.roomDisplayName!.range(of: "$") {
            let imageAttachment = NSTextAttachment()
            imageAttachment.image = UIImage(named: "dollar")
            
            // Adjust the bounds and baselineOffset for proper alignment
            let imageSize = imageAttachment.image?.size ?? CGSize(width: 20, height: 20) // Set a default size if the image is not available
            let yOffset = (roomNameLabel.font.capHeight - imageSize.height) / 2.0
            imageAttachment.bounds = CGRect(x: 0, y: yOffset, width: imageSize.width, height: imageSize.height)
            
            let imageString = NSAttributedString(attachment: imageAttachment)
            
            // Add a space after the image
            let spaceString = NSAttributedString(string: " ")
            
            // Combine image and space
            let combinedString = NSMutableAttributedString()
            combinedString.append(imageString)
            combinedString.append(spaceString)
            
            attributedString.replaceCharacters(in: NSRange(range, in: viewData.roomDisplayName!), with: combinedString)
        }

        roomNameLabel.attributedText = attributedString
        
        roomAddressLabel.text = viewData.mainRoomAlias
        roomAddressLabel.isHidden = roomAddressLabel.text?.isEmpty ?? true
        roomTopicTextView.text = viewData.roomTopic
        topicContainerView.isHidden = roomTopicTextView.text?.isEmpty ?? true
        securityTitleLabel.text = VectorL10n.securitySettingsTitle
        securityInformationLabel.text = viewData.isDirect ?
            VectorL10n.roomParticipantsSecurityInformationRoomEncryptedForDm :
            VectorL10n.roomParticipantsSecurityInformationRoomEncrypted
        securityContainerView.isHidden = !viewData.isEncrypted
        if let directUserId = viewData.directUserId {
            presenceIndicatorView.configure(userId: directUserId, presence: viewData.directUserPresence)
        } else {
            presenceIndicatorView.stopListeningPresenceUpdates()
        }
        updateBadgeImageViewPosition(isPresenceDisplayed: viewData.directUserPresence != .unknown)
    }
    
    private func updateBadgeImageViewPosition(isPresenceDisplayed: Bool) {
        guard badgeImageView.image != nil else {
            badgeImageView.isHidden = true
            return
        }

        badgeImageView.isHidden = false
        // Update badge position if it doesn't match expectation.
        // If presence is displayed, badge should be in the name stack.
        let isBadgeInRoomNameStackView = roomNameStackView.arrangedSubviews.contains(badgeImageView)
        switch (isPresenceDisplayed, isBadgeInRoomNameStackView) {
        case (true, false):
            badgeImageView.removeFromSuperview()
            roomNameStackView.insertArrangedSubview(badgeImageView, at: 0)
        case (false, true):
            roomNameStackView.removeArrangedSubview(badgeImageView)
            avatarContainerView.addSubview(badgeImageView)
            badgeImageView.trailingAnchor.constraint(equalTo: avatarContainerView.trailingAnchor).isActive = true
            badgeImageView.bottomAnchor.constraint(equalTo: avatarContainerView.bottomAnchor).isActive = true
        case (_, _):
            break
        }
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
        presenceIndicatorView.borderColor = theme.headerBackgroundColor
    }
    
}

extension RoomInfoBasicView: PresenceIndicatorViewDelegate {
    func presenceIndicatorViewDidUpdateVisibility(_ presenceIndicatorView: PresenceIndicatorView, isHidden: Bool) {
        updateBadgeImageViewPosition(isPresenceDisplayed: !isHidden)
    }
}
