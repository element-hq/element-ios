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
    private var isJoined: Bool = false
    private var showCancel: Bool = true

    // MARK: Outlets

    @IBOutlet private weak var inviterPanelHeight: NSLayoutConstraint!
    @IBOutlet private weak var inviterAvatarView: RoomAvatarView!
    @IBOutlet private weak var inviterTitleLabel: UILabel!
    @IBOutlet private weak var inviterIdLabel: UILabel!
    @IBOutlet private weak var inviterSeparatorView: UIView!

    @IBOutlet private weak var avatarView: SpaceAvatarView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var closeButton: UIButton!
    @IBOutlet private weak var spaceTypeIconView: UIImageView!
    @IBOutlet private weak var spaceTypeLabel: UILabel!
    @IBOutlet private weak var topicLabel: UILabel!
    @IBOutlet private weak var topicScrollView: UIScrollView!

    @IBOutlet private weak var joinButtonTopMargin: NSLayoutConstraint!
    @IBOutlet private weak var joinButtonBottomMargin: NSLayoutConstraint!
    @IBOutlet private weak var joinButton: UIButton!
    @IBOutlet private weak var declineButton: UIButton!
    @IBOutlet private weak var acceptButton: UIButton!
    @IBOutlet private weak var inviteActionPanel: UIView!

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
        
        self.setupViews()
        self.activityPresenter = ActivityIndicatorPresenter()
        self.errorPresenter = MXKErrorAlertPresentation()

        self.registerThemeServiceDidChangeThemeNotification()
        self.update(theme: self.theme)
        
        self.viewModel.viewDelegate = self
        self.viewModel.process(viewAction: .loadData)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.theme.statusBarStyle
    }
    
    override var preferredContentSize: CGSize {
        get {
            return CGSize(width: Constants.popoverWidth, height: self.intrisicHeight(with: Constants.popoverWidth))
        }
        set {
            super.preferredContentSize = newValue
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.viewModel.process(viewAction: .dismissed)
    }
    
    // MARK: - IBActions
    
    @IBAction private func closeAction(sender: UIButton) {
        self.viewModel.process(viewAction: .dismiss)
    }
    
    @IBAction private func joinAction(sender: UIButton) {
        if isJoined {
            self.viewModel.process(viewAction: .open)
        } else {
            self.viewModel.process(viewAction: .join)
        }
    }
    
    @IBAction private func leaveAction(sender: UIButton) {
        self.viewModel.process(viewAction: .leave)
    }
    
    // MARK: - Private
    
    private func update(theme: Theme) {
        self.theme = theme
        
        self.view.backgroundColor = theme.colors.background
        
        self.inviterAvatarView.update(theme: theme)
        self.inviterTitleLabel.textColor = theme.colors.secondaryContent
        self.inviterTitleLabel.font = theme.fonts.calloutSB
        self.inviterIdLabel.textColor = theme.colors.secondaryContent
        self.inviterIdLabel.font = theme.fonts.footnote
        self.inviterSeparatorView.backgroundColor = theme.colors.navigation
        
        self.titleLabel.textColor = theme.colors.primaryContent
        self.titleLabel.font = theme.fonts.title3SB
        self.closeButton.backgroundColor = theme.roomInputTextBorder
        self.closeButton.tintColor = theme.noticeSecondaryColor
        self.avatarView.update(theme: theme)

        self.spaceTypeIconView.tintColor = theme.colors.tertiaryContent
        self.spaceTypeLabel.font = theme.fonts.callout
        self.spaceTypeLabel.textColor = theme.colors.tertiaryContent
        self.topicLabel.font = theme.fonts.caption1
        self.topicLabel.textColor = theme.colors.tertiaryContent

        apply(theme: theme, on: self.joinButton)
        apply(theme: theme, on: self.acceptButton)
        
        self.declineButton.layer.borderColor = theme.colors.alert.cgColor
        self.declineButton.tintColor = theme.colors.alert
        self.declineButton.setTitleColor(theme.colors.alert, for: .normal)
        self.declineButton.titleLabel?.font = theme.fonts.body
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
        self.update(theme: ThemeService.shared().theme)
    }
    
    private func setupViews() {
        self.closeButton.layer.masksToBounds = true
        self.closeButton.layer.cornerRadius = self.closeButton.bounds.height / 2
        self.closeButton.isHidden = !self.showCancel
        
        self.setup(button: self.joinButton, withTitle: VectorL10n.join)
        self.setup(button: self.acceptButton, withTitle: VectorL10n.accept)
        self.setup(button: self.declineButton, withTitle: VectorL10n.decline)
        self.declineButton.layer.borderWidth = 1.0
    }
    
    private func setup(button: UIButton, withTitle title: String) {
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 8.0
        button.setTitle(title, for: .normal)
    }
    
    private func render(viewState: SpaceDetailViewState) {
        switch viewState {
        case .loading:
            self.renderLoading()
        case .loaded(let parameters):
            self.renderLoaded(parameters: parameters)
        case .error(let error):
            self.render(error: error)
        }
    }
    
    private func renderLoading() {
        self.activityPresenter.presentActivityIndicator(on: self.view, animated: true)
    }
    
    private func renderLoaded(parameters: SpaceDetailLoadedParameters) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        
        switch parameters.membership {
        case .invite:
            self.title = VectorL10n.spaceInviteNavTitle
            self.joinButton.isHidden = true
            self.inviteActionPanel.isHidden = false
        case .join:
            self.title = VectorL10n.spaceDetailNavTitle
            self.inviterPanelHeight.constant = 0
            self.joinButton.setTitle(VectorL10n.open, for: .normal)
            self.isJoined = true
        default:
            self.title = VectorL10n.spaceDetailNavTitle
            self.inviterPanelHeight.constant = 0
        }
        
        let avatarViewData = AvatarViewData(matrixItemId: parameters.spaceId,
                                            displayName: parameters.displayName,
                                            avatarUrl: parameters.avatarUrl,
                                            mediaManager: self.mediaManager,
                                            fallbackImage: .matrixItem(parameters.spaceId, parameters.displayName))

        self.titleLabel.text = parameters.displayName
        self.avatarView.fill(with: avatarViewData)
        self.topicLabel.text = parameters.topic
        
        let joinRuleString = parameters.joinRule == .public ? VectorL10n.spacePublicJoinRule : VectorL10n.spacePrivateJoinRule
        
        let membersCount = parameters.membersCount
        let membersString = membersCount == 1 ? VectorL10n.roomTitleOneMember : VectorL10n.roomTitleMembers("\(membersCount)")
        self.spaceTypeLabel.text = "\(joinRuleString) · \(membersString)"
        
        let joinRuleIcon = parameters.joinRule == .public ? Asset.Images.spaceTypeIcon : Asset.Images.spacePrivateIcon
        self.spaceTypeIconView.image = joinRuleIcon.image
        
        self.inviterIdLabel.text = parameters.inviterId?.components(separatedBy: ":").first
        if let inviterId = parameters.inviterId {
            let newInviterTitle = (parameters.inviter?.displayname ?? inviterId).components(separatedBy: ":").first ?? ""
            self.inviterTitleLabel.text = "\(newInviterTitle) invited you"
            
            if let inviter = parameters.inviter {
                let avatarViewData = AvatarViewData(matrixItemId: newInviterTitle, displayName: newInviterTitle, avatarUrl: inviter.avatarUrl, mediaManager: self.mediaManager, fallbackImage: .matrixItem(newInviterTitle, inviter.displayname))
                self.inviterAvatarView.fill(with: avatarViewData)
            }
        }
        
        view.layoutIfNeeded()
    }
    
    private func render(error: Error) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        self.errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
    }
    
    private func intrisicHeight(with width: CGFloat) -> CGFloat {
        let topicHeight = min(self.topicLabel.sizeThatFits(CGSize(width: width - self.topicScrollView.frame.minX * 2, height: 0)).height, Constants.topicMaxHeight)
        return self.topicScrollView.frame.minY + topicHeight + self.joinButton.frame.height + self.joinButtonTopMargin.constant + self.joinButtonBottomMargin.constant
    }
}

// MARK: - SlidingModalPresentable

extension SpaceDetailViewController: SlidingModalPresentable {
    
    func allowsDismissOnBackgroundTap() -> Bool {
        return true
    }
    
    func layoutHeightFittingWidth(_ width: CGFloat) -> CGFloat {
        return self.intrisicHeight(with: width) + self.joinButtonTopMargin.constant + self.joinButtonBottomMargin.constant
    }
    
}

// MARK: - SpaceDetailViewModelViewDelegate

extension SpaceDetailViewController: SpaceDetailViewModelViewDelegate {
    func spaceDetailViewModel(_ viewModel: SpaceDetailViewModelType, didUpdateViewState viewSate: SpaceDetailViewState) {
        self.render(viewState: viewSate)
    }
}
