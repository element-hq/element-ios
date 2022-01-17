// File created from ScreenTemplate
// $ createScreen.sh Spaces/SpaceRoomList/SpaceChildRoomDetail ShowSpaceChildRoomDetail
/*
 Copyright 2021 New Vector Ltd
 
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

final class SpaceRoomPreviewViewController: UIViewController {
    
    // MARK: - Constants
    
    private enum Constants {
        static let popoverWidth: CGFloat = 300
    }
    
    // MARK: Outlets

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var avatarView: RoomAvatarView!
    @IBOutlet private weak var spaceAvatarView: SpaceAvatarView!
    @IBOutlet private weak var userIconView: UIImageView!
    @IBOutlet private weak var membersLabel: UILabel!
    @IBOutlet private weak var roomsIconView: UIImageView!
    @IBOutlet private weak var roomsLabel: UILabel!
    @IBOutlet private weak var topicLabel: UILabel!
    @IBOutlet private weak var topicLabelBottomMargin: NSLayoutConstraint!
    @IBOutlet private weak var spaceTagView: UIView!
    @IBOutlet private weak var spaceTagLabel: UILabel!

    // MARK: Private

    private var theme: Theme!
    private var roomInfo: MXSpaceChildInfo!
    private var avatarViewData: AvatarViewDataProtocol!
    
    // MARK: - Setup
    
    class func instantiate(with roomInfo: MXSpaceChildInfo, avatarViewData: AvatarViewDataProtocol!) -> SpaceRoomPreviewViewController {
        let viewController = StoryboardScene.SpaceRoomPreviewViewController.initialScene.instantiate()
        viewController.roomInfo = roomInfo
        viewController.avatarViewData = avatarViewData
        viewController.theme = ThemeService.shared().theme
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        setupView()
        self.registerThemeServiceDidChangeThemeNotification()
        self.update(theme: self.theme)
    }

    override var preferredContentSize: CGSize {
        get {
            return CGSize(width: Constants.popoverWidth, height: self.intrisicHeight(with: Constants.popoverWidth))
        }
        set {
            super.preferredContentSize = newValue
        }
    }
    
    // MARK: - Private
    
    private func update(theme: Theme) {
        self.theme = theme
        
        self.view.backgroundColor = theme.headerBackgroundColor
        
        if let navigationBar = self.navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }

        self.titleLabel.textColor = theme.textPrimaryColor
        self.titleLabel.font = theme.fonts.title3SB
        
        self.membersLabel.font = theme.fonts.caption1
        self.membersLabel.textColor = theme.colors.tertiaryContent
        
        self.topicLabel.font = theme.fonts.caption1
        self.topicLabel.textColor = theme.colors.tertiaryContent
        
        self.userIconView.tintColor = theme.colors.tertiaryContent
        
        self.roomsIconView.tintColor = theme.colors.tertiaryContent
        self.roomsLabel.font = theme.fonts.caption1
        self.roomsLabel.textColor = theme.colors.tertiaryContent
        
        self.spaceTagView.backgroundColor = theme.colors.quinaryContent
        self.spaceTagLabel.font = theme.fonts.caption1
        self.spaceTagLabel.textColor = theme.colors.tertiaryContent
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
    
    private func setupView() {
        self.titleLabel.text = roomInfo.displayName
        
        self.spaceTagView.layer.masksToBounds = true
        self.spaceTagView.layer.cornerRadius = 2
        self.spaceTagView.isHidden = roomInfo.roomType != .space
        self.spaceTagLabel.text = VectorL10n.spaceTag

        self.avatarView.isHidden = roomInfo.roomType == .space
        self.spaceAvatarView.isHidden = roomInfo.roomType != .space
        
        if !self.avatarView.isHidden {
            self.avatarView.fill(with: avatarViewData)
        }
        if !self.spaceAvatarView.isHidden {
            self.spaceAvatarView.fill(with: avatarViewData)
        }
        self.membersLabel.text = roomInfo.activeMemberCount == 1 ? VectorL10n.roomTitleOneMember : VectorL10n.roomTitleMembers("\(roomInfo.activeMemberCount)")
        if roomInfo.childrenIds.count == 1 {
            self.roomsLabel.text = VectorL10n.spacesExploreRoomsOneRoom
        } else {
            self.roomsLabel.text = VectorL10n.spacesExploreRoomsRoomNumber("\(roomInfo.childrenIds.count)")
        }
        self.topicLabel.text = roomInfo.topic
        topicLabelBottomMargin.constant = self.topicLabel.text.isEmptyOrNil ? 0 : 16

        self.roomsIconView.isHidden = roomInfo.roomType != .space
        self.roomsLabel.isHidden = roomInfo.roomType != .space
    }
    
    private func intrisicHeight(with width: CGFloat) -> CGFloat {
        if self.topicLabel.text.isEmptyOrNil {
            return self.topicLabel.frame.minY
        }
        
        let topicHeight = self.topicLabel.sizeThatFits(CGSize(width: width - self.topicLabel.frame.minX * 2, height: 0)).height
        return self.topicLabel.frame.minY + topicHeight + 16
    }
}
