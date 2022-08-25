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

import MatrixSDK
import UIKit

/// `RoomContextPreviewViewController` is used to dsplay room preview data within a `UIContextMenuContentPreviewProvider`
final class RoomContextPreviewViewController: UIViewController {
    // MARK: - Constants
    
    private enum Constants {
        static let popoverWidth: CGFloat = 300
    }
    
    // MARK: Outlets

    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var avatarView: RoomAvatarView!
    @IBOutlet private var spaceAvatarView: SpaceAvatarView!
    @IBOutlet private var userIconView: UIImageView!
    @IBOutlet private var membersLabel: UILabel!
    @IBOutlet private var roomsIconView: UIImageView!
    @IBOutlet private var roomsLabel: UILabel!
    @IBOutlet private var topicLabel: UILabel!
    @IBOutlet private var topicLabelBottomMargin: NSLayoutConstraint!
    @IBOutlet private var spaceTagView: UIView!
    @IBOutlet private var spaceTagLabel: UILabel!
    @IBOutlet private var stackView: UIStackView!
    @IBOutlet private var inviteHeaderView: UIView!
    @IBOutlet private var inviterAvatarView: UserAvatarView!
    @IBOutlet private var inviteTitleLabel: UILabel!
    @IBOutlet private var inviteDetailLabel: UILabel!
    @IBOutlet private var inviteSeparatorView: UIView!

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
        registerThemeServiceDidChangeThemeNotification()
        update(theme: theme)
        viewModel.process(viewAction: .loadData)
    }

    override var preferredContentSize: CGSize {
        get {
            CGSize(width: Constants.popoverWidth, height: intrisicHeight(with: Constants.popoverWidth))
        }
        set {
            super.preferredContentSize = newValue
        }
    }
    
    // MARK: - Private
    
    private func update(theme: Theme) {
        self.theme = theme
        
        view.backgroundColor = theme.headerBackgroundColor
        
        if let navigationBar = navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }

        titleLabel.textColor = theme.textPrimaryColor
        titleLabel.font = theme.fonts.title3SB
        
        membersLabel.font = theme.fonts.caption1
        membersLabel.textColor = theme.colors.tertiaryContent
        
        topicLabel.font = theme.fonts.caption1
        topicLabel.textColor = theme.colors.tertiaryContent
        
        userIconView.tintColor = theme.colors.tertiaryContent
        
        roomsIconView.tintColor = theme.colors.tertiaryContent
        roomsLabel.font = theme.fonts.caption1
        roomsLabel.textColor = theme.colors.tertiaryContent
        
        spaceTagView.backgroundColor = theme.colors.quinaryContent
        spaceTagLabel.font = theme.fonts.caption1
        spaceTagLabel.textColor = theme.colors.tertiaryContent
        
        inviteTitleLabel.textColor = theme.colors.tertiaryContent
        inviteTitleLabel.font = theme.fonts.calloutSB
        
        inviteDetailLabel.textColor = theme.colors.tertiaryContent
        inviteDetailLabel.font = theme.fonts.caption1
        
        inviteSeparatorView.backgroundColor = theme.colors.quinaryContent
        inviterAvatarView.alpha = 0.7
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        update(theme: ThemeService.shared().theme)
    }
    
    private func renderLoaded(with parameters: RoomContextPreviewLoadedParameters) {
        titleLabel.text = parameters.displayName

        spaceTagView.isHidden = parameters.roomType != .space
        
        avatarView.isHidden = parameters.roomType == .space
        spaceAvatarView.isHidden = parameters.roomType != .space
        
        let avatarViewData = AvatarViewData(matrixItemId: parameters.roomId,
                                            displayName: parameters.displayName,
                                            avatarUrl: parameters.avatarUrl,
                                            mediaManager: mediaManager,
                                            fallbackImage: .matrixItem(parameters.roomId, parameters.displayName))

        if !avatarView.isHidden {
            avatarView.fill(with: avatarViewData)
        }
        if !spaceAvatarView.isHidden {
            spaceAvatarView.fill(with: avatarViewData)
        }
        
        if parameters.membership != .invite {
            stackView.removeArrangedSubview(inviteHeaderView)
            inviteHeaderView.isHidden = true
        }
        
        membersLabel.text = parameters.membersCount == 1 ? VectorL10n.roomTitleOneMember : VectorL10n.roomTitleMembers("\(parameters.membersCount)")
        
        if let inviterId = parameters.inviterId {
            if let inviter = parameters.inviter {
                let avatarData = AvatarViewData(matrixItemId: inviterId,
                                                displayName: inviter.displayname,
                                                avatarUrl: inviter.avatarUrl,
                                                mediaManager: mediaManager,
                                                fallbackImage: .matrixItem(inviterId, inviter.displayname))
                inviterAvatarView.fill(with: avatarData)
                if let inviterName = inviter.displayname {
                    inviteTitleLabel.text = VectorL10n.noticeRoomInviteYou(inviterName)
                    inviteDetailLabel.text = inviterId
                } else {
                    inviteTitleLabel.text = VectorL10n.noticeRoomInviteYou(inviterId)
                }
            } else {
                inviteTitleLabel.text = VectorL10n.noticeRoomInviteYou(inviterId)
            }
        }
        
        topicLabel.text = parameters.topic
        topicLabelBottomMargin.constant = topicLabel.text.isEmptyOrNil ? 0 : 16

        roomsIconView.isHidden = parameters.roomType != .space
        roomsLabel.isHidden = parameters.roomType != .space
        
        view.layoutIfNeeded()
    }
    
    private func setupView() {
        spaceTagView.layer.masksToBounds = true
        spaceTagView.layer.cornerRadius = 2
        spaceTagLabel.text = VectorL10n.spaceTag
    }
    
    private func intrisicHeight(with width: CGFloat) -> CGFloat {
        if topicLabel.text.isEmptyOrNil {
            return topicLabel.frame.minY
        }

        let topicHeight = topicLabel.sizeThatFits(CGSize(width: width - topicLabel.frame.minX * 2, height: 0)).height
        return topicLabel.frame.minY + topicHeight + 16
    }
}

// MARK: - RoomContextPreviewViewModelViewDelegate

extension RoomContextPreviewViewController: RoomContextPreviewViewModelViewDelegate {
    func roomContextPreviewViewModel(_ viewModel: RoomContextPreviewViewModelProtocol, didUpdateViewState viewSate: RoomContextPreviewViewState) {
        switch viewSate {
        case .loaded(let parameters):
            renderLoaded(with: parameters)
        }
    }
}
