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
import MatrixSDK

/// `RoomContextPreviewViewController` is used to dsplay room preview data within a `UIContextMenuContentPreviewProvider`
final class RoomContextPreviewViewController: UIViewController {
    
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
    @IBOutlet private weak var stackView: UIStackView!
    @IBOutlet private weak var inviteHeaderView: UIView!
    @IBOutlet private weak var inviterAvatarView: UserAvatarView!
    @IBOutlet private weak var inviteTitleLabel: UILabel!
    @IBOutlet private weak var inviteDetailLabel: UILabel!
    @IBOutlet private weak var inviteSeparatorView: UIView!

    // MARK: Private

    private var theme: Theme!
    private var viewModel: RoomContextPreviewViewModelProtocol!
    private var mediaManager: MXMediaManager?
    
    // MARK: - Setup
    
    class func instantiate(with viewModel: RoomContextPreviewViewModelProtocol, mediaManager: MXMediaManager?) -> RoomContextPreviewViewController {
        let viewController = StoryboardScene.RoomContextPreviewViewController.initialScene.instantiate()
        viewController.viewModel = viewModel
        viewController.mediaManager = mediaManager
        viewController.theme = ThemeService.shared().theme
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        viewModel.viewDelegate = self
        
        setupView()
        self.registerThemeServiceDidChangeThemeNotification()
        self.update(theme: self.theme)
        self.viewModel.process(viewAction: .loadData)
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
        
        self.inviteTitleLabel.textColor = theme.colors.tertiaryContent
        self.inviteTitleLabel.font = theme.fonts.calloutSB
        
        self.inviteDetailLabel.textColor = theme.colors.tertiaryContent
        self.inviteDetailLabel.font = theme.fonts.caption1
        
        self.inviteSeparatorView.backgroundColor = theme.colors.quinaryContent
        self.inviterAvatarView.alpha = 0.7
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
    
    private func renderLoaded(with parameters: RoomContextPreviewLoadedParameters) {
        self.titleLabel.text = parameters.displayName

        self.spaceTagView.isHidden = parameters.roomType != .space
        
        self.avatarView.isHidden = parameters.roomType == .space
        self.spaceAvatarView.isHidden = parameters.roomType != .space
        
        let avatarViewData = AvatarViewData(matrixItemId: parameters.roomId,
                                            displayName: parameters.displayName,
                                            avatarUrl: parameters.avatarUrl,
                                            mediaManager: mediaManager,
                                            fallbackImage: .matrixItem(parameters.roomId, parameters.displayName))

        if !self.avatarView.isHidden {
            self.avatarView.fill(with: avatarViewData)
        }
        if !self.spaceAvatarView.isHidden {
            self.spaceAvatarView.fill(with: avatarViewData)
        }
        
        if parameters.membership != .invite {
            self.stackView.removeArrangedSubview(self.inviteHeaderView)
            self.inviteHeaderView.isHidden = true
        }
        
        self.membersLabel.text = parameters.membersCount == 1 ? VectorL10n.roomTitleOneMember : VectorL10n.roomTitleMembers("\(parameters.membersCount)")
        
        if let inviterId = parameters.inviterId {
            if let inviter = parameters.inviter {
                let avatarData = AvatarViewData(matrixItemId: inviterId,
                                                displayName: inviter.displayname,
                                                avatarUrl: inviter.avatarUrl,
                                                mediaManager: mediaManager,
                                                fallbackImage: .matrixItem(inviterId, inviter.displayname))
                self.inviterAvatarView.fill(with: avatarData)
                if let inviterName = inviter.displayname {
                    self.inviteTitleLabel.text = VectorL10n.noticeRoomInviteYou(inviterName)
                    self.inviteDetailLabel.text = inviterId
                } else {
                    self.inviteTitleLabel.text = VectorL10n.noticeRoomInviteYou(inviterId)
                }
            } else {
                self.inviteTitleLabel.text = VectorL10n.noticeRoomInviteYou(inviterId)
            }
        }
        
        self.topicLabel.text = parameters.topic
        topicLabelBottomMargin.constant = self.topicLabel.text.isEmptyOrNil ? 0 : 16

        self.roomsIconView.isHidden = parameters.roomType != .space
        self.roomsLabel.isHidden = parameters.roomType != .space
        
        self.view.layoutIfNeeded()
    }
    
    private func setupView() {
        self.spaceTagView.layer.masksToBounds = true
        self.spaceTagView.layer.cornerRadius = 2
        self.spaceTagLabel.text = VectorL10n.spaceTag
    }
    
    private func intrisicHeight(with width: CGFloat) -> CGFloat {
        if self.topicLabel.text.isEmptyOrNil {
            return self.topicLabel.frame.minY
        }

        let topicHeight = self.topicLabel.sizeThatFits(CGSize(width: width - self.topicLabel.frame.minX * 2, height: 0)).height
        return self.topicLabel.frame.minY + topicHeight + 16
    }
}

// MARK: - RoomContextPreviewViewModelViewDelegate

extension RoomContextPreviewViewController: RoomContextPreviewViewModelViewDelegate {
    func roomContextPreviewViewModel(_ viewModel: RoomContextPreviewViewModelProtocol, didUpdateViewState viewSate: RoomContextPreviewViewState) {
        switch viewSate {
        case .loaded(let parameters):
            self.renderLoaded(with: parameters)
        }
    }
}
