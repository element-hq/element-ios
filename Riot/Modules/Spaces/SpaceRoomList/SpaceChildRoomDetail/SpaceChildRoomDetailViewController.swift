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

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var closeButton: UIButton!
    @IBOutlet private weak var joinButton: UIButton!
    @IBOutlet private weak var joinButtonTopMargin: NSLayoutConstraint!
    @IBOutlet private weak var joinButtonBottomMargin: NSLayoutConstraint!
    @IBOutlet private weak var avatarView: RoomAvatarView!
    @IBOutlet private weak var userIconView: UIImageView!
    @IBOutlet private weak var membersLabel: UILabel!
    @IBOutlet private weak var topicLabel: UILabel!
    @IBOutlet private weak var topicScrollView: UIScrollView!

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
        
        self.setupViews()
        self.activityPresenter = ActivityIndicatorPresenter()
        self.errorPresenter = MXKErrorAlertPresentation()
        
        self.registerThemeServiceDidChangeThemeNotification()
        self.update(theme: self.theme)
        
        self.viewModel.viewDelegate = self

        self.viewModel.process(viewAction: .loadData)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        AnalyticsScreenTracker.trackScreen(.roomPreview)
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
    
    // MARK: - Private
    
    private func update(theme: Theme) {
        self.theme = theme
        
        self.view.backgroundColor = theme.headerBackgroundColor
        
        if let navigationBar = self.navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }

        self.titleLabel.textColor = theme.textPrimaryColor
        self.titleLabel.font = theme.fonts.title3SB
        self.joinButton.backgroundColor = theme.colors.accent
        self.joinButton.tintColor = theme.colors.background
        self.joinButton.setTitleColor(theme.colors.background, for: .normal)
        self.membersLabel.font = theme.fonts.caption1
        self.membersLabel.textColor = theme.colors.tertiaryContent
        self.topicLabel.font = theme.fonts.caption1
        self.topicLabel.textColor = theme.colors.tertiaryContent
        self.userIconView.tintColor = theme.colors.tertiaryContent
        self.closeButton.backgroundColor = theme.roomInputTextBorder
        self.closeButton.tintColor = theme.noticeSecondaryColor
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

        self.title = VectorL10n.roomDetailsTitle
        self.joinButton.layer.masksToBounds = true
        self.joinButton.layer.cornerRadius = 8.0
        self.joinButton.setTitle(VectorL10n.join, for: .normal)
    }

    private func render(viewState: SpaceChildRoomDetailViewState) {
        switch viewState {
        case .loading:
            self.renderLoading()
        case .loaded(let roomInfo, let avatarViewData, let isJoined):
            self.renderLoaded(roomInfo: roomInfo, avatarViewData: avatarViewData, isJoined: isJoined)
        case .error(let error):
            self.render(error: error)
        }
    }
    
    private func renderLoading() {
        self.activityPresenter.presentActivityIndicator(on: self.view, animated: true)
    }
    
    private func renderLoaded(roomInfo: MXSpaceChildInfo, avatarViewData: AvatarViewData, isJoined: Bool) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        self.titleLabel.text = roomInfo.displayName
        self.avatarView.fill(with: avatarViewData)
        self.membersLabel.text = roomInfo.activeMemberCount == 1 ? VectorL10n.roomTitleOneMember : VectorL10n.roomTitleMembers("\(roomInfo.activeMemberCount)")
        self.topicLabel.text = roomInfo.topic
        self.joinButton .setTitle(isJoined ? VectorL10n.open : VectorL10n.join, for: .normal)
    }
    
    private func render(error: Error) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        self.errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
    }
    
    private func intrisicHeight(with width: CGFloat) -> CGFloat {
        let topicHeight = min(self.topicLabel.sizeThatFits(CGSize(width: width - self.topicScrollView.frame.minX * 2, height: 0)).height, Constants.topicMaxHeight)
        return self.topicScrollView.frame.minY + topicHeight + self.joinButton.frame.height
    }

    // MARK: - IBActions
    
    @IBAction private func closeAction(sender: UIButton) {
        self.viewModel.process(viewAction: .cancel)
    }
    
    @IBAction private func doneButtonAction(_ sender: Any) {
        self.viewModel.process(viewAction: .complete)
    }
}


// MARK: - SpaceChildRoomDetailViewModelViewDelegate
extension SpaceChildRoomDetailViewController: SpaceChildRoomDetailViewModelViewDelegate {

    func spaceChildRoomDetailViewModel(_ viewModel: SpaceChildRoomDetailViewModelType, didUpdateViewState viewSate: SpaceChildRoomDetailViewState) {
        self.render(viewState: viewSate)
    }
}

// MARK: - SlidingModalPresentable

extension SpaceChildRoomDetailViewController: SlidingModalPresentable {
    
    func allowsDismissOnBackgroundTap() -> Bool {
        return true
    }
    
    func layoutHeightFittingWidth(_ width: CGFloat) -> CGFloat {
        return self.intrisicHeight(with: width) + self.joinButtonTopMargin.constant + self.joinButtonBottomMargin.constant
    }

}
