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

import Foundation

class SpaceDetailViewController: UIViewController {
    // MARK: - Constants
    
    private enum Constants {
        static let popoverWidth: CGFloat = 320
        static let topicMaxHeight: CGFloat = 105
    }
    
    // MARK: Private

    private var theme: Theme!
    private var mediaManager: MXMediaManager!
    private var viewModel: SpaceDetailViewModelType!
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!
    private var isJoined = false
    private var showCancel = true

    // MARK: Outlets

    @IBOutlet private var inviterPanelHeight: NSLayoutConstraint!
    @IBOutlet private var inviterAvatarView: RoomAvatarView!
    @IBOutlet private var inviterTitleLabel: UILabel!
    @IBOutlet private var inviterIdLabel: UILabel!
    @IBOutlet private var inviterSeparatorView: UIView!

    @IBOutlet private var avatarView: SpaceAvatarView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var closeButton: UIButton!
    @IBOutlet private var spaceTypeIconView: UIImageView!
    @IBOutlet private var spaceTypeLabel: UILabel!
    @IBOutlet private var topicLabel: UILabel!
    @IBOutlet private var topicScrollView: UIScrollView!

    @IBOutlet private var joinButtonTopMargin: NSLayoutConstraint!
    @IBOutlet private var joinButtonBottomMargin: NSLayoutConstraint!
    @IBOutlet private var joinButton: UIButton!
    @IBOutlet private var declineButton: UIButton!
    @IBOutlet private var acceptButton: UIButton!
    @IBOutlet private var inviteActionPanel: UIView!

    // MARK: - Setup
    
    class func instantiate(mediaManager: MXMediaManager, viewModel: SpaceDetailViewModelType!, showCancel: Bool) -> SpaceDetailViewController {
        let viewController = StoryboardScene.SpaceDetailViewController.initialScene.instantiate()
        viewController.mediaManager = mediaManager
        viewController.viewModel = viewModel
        viewController.theme = ThemeService.shared().theme
        viewController.showCancel = showCancel
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        setupViews()
        activityPresenter = ActivityIndicatorPresenter()
        errorPresenter = MXKErrorAlertPresentation()

        registerThemeServiceDidChangeThemeNotification()
        update(theme: theme)
        
        viewModel.viewDelegate = self
        viewModel.process(viewAction: .loadData)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        self.theme.statusBarStyle
    }
    
    override var preferredContentSize: CGSize {
        get {
            CGSize(width: Constants.popoverWidth, height: self.intrisicHeight(with: Constants.popoverWidth))
        }
        set {
            super.preferredContentSize = newValue
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        viewModel.process(viewAction: .dismissed)
    }
    
    // MARK: - IBActions
    
    @IBAction private func closeAction(sender: UIButton) {
        viewModel.process(viewAction: .dismiss)
    }
    
    @IBAction private func joinAction(sender: UIButton) {
        if isJoined {
            viewModel.process(viewAction: .open)
        } else {
            viewModel.process(viewAction: .join)
        }
    }
    
    @IBAction private func leaveAction(sender: UIButton) {
        viewModel.process(viewAction: .leave)
    }
    
    // MARK: - Private
    
    private func update(theme: Theme) {
        self.theme = theme
        
        view.backgroundColor = theme.colors.background
        
        inviterAvatarView.update(theme: theme)
        inviterTitleLabel.textColor = theme.colors.secondaryContent
        inviterTitleLabel.font = theme.fonts.calloutSB
        inviterIdLabel.textColor = theme.colors.secondaryContent
        inviterIdLabel.font = theme.fonts.footnote
        inviterSeparatorView.backgroundColor = theme.colors.navigation
        
        titleLabel.textColor = theme.colors.primaryContent
        titleLabel.font = theme.fonts.title3SB
        closeButton.backgroundColor = theme.roomInputTextBorder
        closeButton.tintColor = theme.noticeSecondaryColor
        avatarView.update(theme: theme)

        spaceTypeIconView.tintColor = theme.colors.tertiaryContent
        spaceTypeLabel.font = theme.fonts.callout
        spaceTypeLabel.textColor = theme.colors.tertiaryContent
        topicLabel.font = theme.fonts.caption1
        topicLabel.textColor = theme.colors.tertiaryContent

        apply(theme: theme, on: joinButton)
        apply(theme: theme, on: acceptButton)
        
        declineButton.layer.borderColor = theme.colors.alert.cgColor
        declineButton.tintColor = theme.colors.alert
        declineButton.setTitleColor(theme.colors.alert, for: .normal)
        declineButton.titleLabel?.font = theme.fonts.body
    }
    
    private func apply(theme: Theme, on button: UIButton) {
        button.backgroundColor = theme.colors.accent
        button.tintColor = theme.colors.background
        button.setTitleColor(theme.colors.background, for: .normal)
        button.titleLabel?.font = theme.fonts.bodySB
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        update(theme: ThemeService.shared().theme)
    }
    
    private func setupViews() {
        closeButton.layer.masksToBounds = true
        closeButton.layer.cornerRadius = closeButton.bounds.height / 2
        closeButton.isHidden = !showCancel
        
        setup(button: joinButton, withTitle: VectorL10n.join)
        setup(button: acceptButton, withTitle: VectorL10n.accept)
        setup(button: declineButton, withTitle: VectorL10n.decline)
        declineButton.layer.borderWidth = 1.0
    }
    
    private func setup(button: UIButton, withTitle title: String) {
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 8.0
        button.setTitle(title, for: .normal)
    }
    
    private func render(viewState: SpaceDetailViewState) {
        switch viewState {
        case .loading:
            renderLoading()
        case .loaded(let parameters):
            renderLoaded(parameters: parameters)
        case .error(let error):
            render(error: error)
        }
    }
    
    private func renderLoading() {
        activityPresenter.presentActivityIndicator(on: view, animated: true)
    }
    
    private func renderLoaded(parameters: SpaceDetailLoadedParameters) {
        activityPresenter.removeCurrentActivityIndicator(animated: true)
        
        switch parameters.membership {
        case .invite:
            title = VectorL10n.spaceInviteNavTitle
            joinButton.isHidden = true
            inviteActionPanel.isHidden = false
        case .join:
            title = VectorL10n.spaceDetailNavTitle
            inviterPanelHeight.constant = 0
            joinButton.setTitle(VectorL10n.open, for: .normal)
            isJoined = true
        default:
            title = VectorL10n.spaceDetailNavTitle
            inviterPanelHeight.constant = 0
        }
        
        let avatarViewData = AvatarViewData(matrixItemId: parameters.spaceId,
                                            displayName: parameters.displayName,
                                            avatarUrl: parameters.avatarUrl,
                                            mediaManager: mediaManager,
                                            fallbackImage: .matrixItem(parameters.spaceId, parameters.displayName))

        titleLabel.text = parameters.displayName
        avatarView.fill(with: avatarViewData)
        topicLabel.text = parameters.topic
        
        let joinRuleString = parameters.joinRule == .public ? VectorL10n.spacePublicJoinRule : VectorL10n.spacePrivateJoinRule
        
        let membersCount = parameters.membersCount
        let membersString = membersCount == 1 ? VectorL10n.roomTitleOneMember : VectorL10n.roomTitleMembers("\(membersCount)")
        spaceTypeLabel.text = "\(joinRuleString) · \(membersString)"
        
        let joinRuleIcon = parameters.joinRule == .public ? Asset.Images.spaceTypeIcon : Asset.Images.spacePrivateIcon
        spaceTypeIconView.image = joinRuleIcon.image
        
        inviterIdLabel.text = parameters.inviterId
        if let inviterId = parameters.inviterId {
            inviterTitleLabel.text = "\(parameters.inviter?.displayname ?? inviterId) invited you"
            
            if let inviter = parameters.inviter {
                let avatarViewData = AvatarViewData(matrixItemId: inviter.userId, displayName: inviter.displayname, avatarUrl: inviter.avatarUrl, mediaManager: mediaManager, fallbackImage: .matrixItem(inviter.userId, inviter.displayname))
                inviterAvatarView.fill(with: avatarViewData)
            }
        }
        
        view.layoutIfNeeded()
    }
    
    private func render(error: Error) {
        activityPresenter.removeCurrentActivityIndicator(animated: true)
        errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
    }
    
    private func intrisicHeight(with width: CGFloat) -> CGFloat {
        let topicHeight = min(topicLabel.sizeThatFits(CGSize(width: width - topicScrollView.frame.minX * 2, height: 0)).height, Constants.topicMaxHeight)
        return topicScrollView.frame.minY + topicHeight + joinButton.frame.height + joinButtonTopMargin.constant + joinButtonBottomMargin.constant
    }
}

// MARK: - SlidingModalPresentable

extension SpaceDetailViewController: SlidingModalPresentable {
    func allowsDismissOnBackgroundTap() -> Bool {
        true
    }
    
    func layoutHeightFittingWidth(_ width: CGFloat) -> CGFloat {
        intrisicHeight(with: width) + joinButtonTopMargin.constant + joinButtonBottomMargin.constant
    }
}

// MARK: - SpaceDetailViewModelViewDelegate

extension SpaceDetailViewController: SpaceDetailViewModelViewDelegate {
    func spaceDetailViewModel(_ viewModel: SpaceDetailViewModelType, didUpdateViewState viewSate: SpaceDetailViewState) {
        render(viewState: viewSate)
    }
}
