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

final class SpaceChildRoomDetailViewController: UIViewController {
    // MARK: - Constants
    
    private enum Constants {
        static let popoverWidth: CGFloat = 300
        static let topicMaxHeight: CGFloat = 105
    }
    
    // MARK: Outlets

    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var closeButton: UIButton!
    @IBOutlet private var joinButton: UIButton!
    @IBOutlet private var joinButtonTopMargin: NSLayoutConstraint!
    @IBOutlet private var joinButtonBottomMargin: NSLayoutConstraint!
    @IBOutlet private var avatarView: RoomAvatarView!
    @IBOutlet private var userIconView: UIImageView!
    @IBOutlet private var membersLabel: UILabel!
    @IBOutlet private var topicLabel: UILabel!
    @IBOutlet private var topicScrollView: UIScrollView!

    // MARK: Private

    private var viewModel: SpaceChildRoomDetailViewModelType!
    private var theme: Theme!
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!

    // MARK: - Setup
    
    class func instantiate(with viewModel: SpaceChildRoomDetailViewModelType) -> SpaceChildRoomDetailViewController {
        let viewController = StoryboardScene.SpaceChildRoomDetailViewController.initialScene.instantiate()
        viewController.viewModel = viewModel
        viewController.theme = ThemeService.shared().theme
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        AnalyticsScreenTracker.trackScreen(.roomPreview)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        self.theme.statusBarStyle
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
        joinButton.backgroundColor = theme.colors.accent
        joinButton.tintColor = theme.colors.background
        joinButton.setTitleColor(theme.colors.background, for: .normal)
        membersLabel.font = theme.fonts.caption1
        membersLabel.textColor = theme.colors.tertiaryContent
        topicLabel.font = theme.fonts.caption1
        topicLabel.textColor = theme.colors.tertiaryContent
        userIconView.tintColor = theme.colors.tertiaryContent
        closeButton.backgroundColor = theme.roomInputTextBorder
        closeButton.tintColor = theme.noticeSecondaryColor
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

        title = VectorL10n.roomDetailsTitle
        joinButton.layer.masksToBounds = true
        joinButton.layer.cornerRadius = 8.0
        joinButton.setTitle(VectorL10n.join, for: .normal)
    }

    private func render(viewState: SpaceChildRoomDetailViewState) {
        switch viewState {
        case .loading:
            renderLoading()
        case .loaded(let roomInfo, let avatarViewData, let isJoined):
            renderLoaded(roomInfo: roomInfo, avatarViewData: avatarViewData, isJoined: isJoined)
        case .error(let error):
            render(error: error)
        }
    }
    
    private func renderLoading() {
        activityPresenter.presentActivityIndicator(on: view, animated: true)
    }
    
    private func renderLoaded(roomInfo: MXSpaceChildInfo, avatarViewData: AvatarViewData, isJoined: Bool) {
        activityPresenter.removeCurrentActivityIndicator(animated: true)
        titleLabel.text = roomInfo.displayName
        avatarView.fill(with: avatarViewData)
        membersLabel.text = roomInfo.activeMemberCount == 1 ? VectorL10n.roomTitleOneMember : VectorL10n.roomTitleMembers("\(roomInfo.activeMemberCount)")
        topicLabel.text = roomInfo.topic
        joinButton.setTitle(isJoined ? VectorL10n.open : VectorL10n.join, for: .normal)
    }
    
    private func render(error: Error) {
        activityPresenter.removeCurrentActivityIndicator(animated: true)
        errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
    }
    
    private func intrisicHeight(with width: CGFloat) -> CGFloat {
        let topicHeight = min(topicLabel.sizeThatFits(CGSize(width: width - topicScrollView.frame.minX * 2, height: 0)).height, Constants.topicMaxHeight)
        return topicScrollView.frame.minY + topicHeight + joinButton.frame.height
    }

    // MARK: - IBActions
    
    @IBAction private func closeAction(sender: UIButton) {
        viewModel.process(viewAction: .cancel)
    }
    
    @IBAction private func doneButtonAction(_ sender: Any) {
        viewModel.process(viewAction: .complete)
    }
}

// MARK: - SpaceChildRoomDetailViewModelViewDelegate

extension SpaceChildRoomDetailViewController: SpaceChildRoomDetailViewModelViewDelegate {
    func spaceChildRoomDetailViewModel(_ viewModel: SpaceChildRoomDetailViewModelType, didUpdateViewState viewSate: SpaceChildRoomDetailViewState) {
        render(viewState: viewSate)
    }
}

// MARK: - SlidingModalPresentable

extension SpaceChildRoomDetailViewController: SlidingModalPresentable {
    func allowsDismissOnBackgroundTap() -> Bool {
        true
    }
    
    func layoutHeightFittingWidth(_ width: CGFloat) -> CGFloat {
        intrisicHeight(with: width) + joinButtonTopMargin.constant + joinButtonBottomMargin.constant
    }
}
