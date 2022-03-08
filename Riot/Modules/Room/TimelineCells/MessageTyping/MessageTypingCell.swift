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

@objcMembers
class MessageTypingCell: MXKTableViewCell, Themable {
    // MARK: - Constants
    
    private enum Constants {
        static let maxPictureCount = 4
        static let pictureSize: CGFloat = 24
        static let pictureMaxMargin: CGFloat = 16
        static let pictureMinMargin: CGFloat = 8
    }

    // MARK: - Outlets
    
    @IBOutlet private weak var additionalUsersLabel: UILabel!
    @IBOutlet private weak var additionalUsersLabelLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var dotsView: DotsView!
    @IBOutlet private weak var dotsViewLeadingConstraint: NSLayoutConstraint!

    // MARK: - members
    
    private var userPictureViews: [MXKImageView] = []
    
    // MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        update(theme: ThemeService.shared().theme)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        for pictureView in userPictureViews {
            pictureView.removeFromSuperview()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        dotsView.isHidden = userPictureViews.count == 0

        guard userPictureViews.count > 0 else {
            return
        }

        additionalUsersLabel?.sizeToFit()
        
        var pictureViewsMaxX: CGFloat = 0
        var xOffset: CGFloat = 0
        for pictureView in userPictureViews {
            pictureView.center = CGPoint(x: Constants.pictureMaxMargin + xOffset + pictureView.bounds.midX, y: self.bounds.midY)
            xOffset += round(pictureView.bounds.maxX * 2 / 3)
            pictureViewsMaxX = pictureView.frame.maxX
        }
        
        let leftMagin: CGFloat = pictureViewsMaxX + (userPictureViews.count == 1 ? Constants.pictureMaxMargin : Constants.pictureMinMargin)
        additionalUsersLabelLeadingConstraint.constant = leftMagin
        
        dotsViewLeadingConstraint?.constant = additionalUsersLabel.text.isEmptyOrNil == true ? leftMagin : leftMagin + 8 + additionalUsersLabel.frame.width
    }
    
    // MARK: - Overrides
    
    override class func defaultReuseIdentifier() -> String {
        return String(describing: self)
    }
    
    override class func nib() -> UINib {
        return UINib(nibName: String(describing: self), bundle: nil)
    }
    
    // MARK: - Themable
    
    func update(theme: Theme) {
        additionalUsersLabel.textColor = theme.textSecondaryColor
        dotsView.highlightedDotColor = theme.textTertiaryColor
        dotsView.dotColor = theme.textSecondaryColor
    }

    
    // MARK: - Business methods
    
    func updateTypingUsers(_ typingUsers: [TypingUserInfo], mediaManager: MXMediaManager) {
        for pictureView in userPictureViews {
            pictureView.removeFromSuperview()
        }
        userPictureViews = []
        
        for user in typingUsers {
            if userPictureViews.count >= Constants.maxPictureCount {
                break
            }

            let pictureView = MXKImageView(frame: CGRect(x: 0, y: 0, width: Constants.pictureSize, height: Constants.pictureSize))
            pictureView.layer.masksToBounds = true
            pictureView.layer.cornerRadius = pictureView.bounds.midX
            
            let defaultavatarImage = AvatarGenerator.generateAvatar(forMatrixItem: user.userId, withDisplayName: user.displayName)
            pictureView.setImageURI(user.avatarUrl, withType: nil, andImageOrientation: .up, toFitViewSize: pictureView.bounds.size, with: MXThumbnailingMethodCrop, previewImage: defaultavatarImage, mediaManager: mediaManager)
            
            userPictureViews.append(pictureView)
            self.contentView.addSubview(pictureView)
        }
        
        switch typingUsers.count {
        case 0:
            additionalUsersLabel.text = nil
        case 1:
            additionalUsersLabel.text = firstUserNameFor(typingUsers)
        default:
            additionalUsersLabel.text = VectorL10n.roomMultipleTypingNotification(firstUserNameFor(typingUsers) ?? "")
        }
        self.setNeedsLayout()
    }
    
    private func firstUserNameFor(_ typingUsers: Array<TypingUserInfo>) -> String? {
        guard let firstUser = typingUsers.first else {
            return nil
        }
        
        return firstUser.displayName.isEmptyOrNil ? firstUser.userId : firstUser.displayName
    }
}
