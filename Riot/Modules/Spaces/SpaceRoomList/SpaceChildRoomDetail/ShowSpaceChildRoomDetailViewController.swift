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

final class ShowSpaceChildRoomDetailViewController: UIViewController {
    
    // MARK: - Constants
    
    private enum Constants {
        static let aConstant: Int = 666
    }
    
    // MARK: - Properties
    
    // MARK: Outlets

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var doneButton: UIButton!
    @IBOutlet private weak var avatarView: RoomAvatarView!
    @IBOutlet private weak var userIconView: UIImageView!
    @IBOutlet private weak var membersLabel: UILabel!
    @IBOutlet private weak var topicLabel: UILabel!

    // MARK: Private

    private var viewModel: ShowSpaceChildRoomDetailViewModelType!
    private var theme: Theme!
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!

    // MARK: - Setup
    
    class func instantiate(with viewModel: ShowSpaceChildRoomDetailViewModelType) -> ShowSpaceChildRoomDetailViewController {
        let viewController = StoryboardScene.ShowSpaceChildRoomDetailViewController.initialScene.instantiate()
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

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.theme.statusBarStyle
    }
    
    override var preferredContentSize: CGSize {
        get {
            return CGSize(width: 320, height: 300)
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
        self.titleLabel.font = theme.fonts.calloutSB
        self.doneButton.backgroundColor = theme.colors.accent
        self.doneButton.tintColor = theme.colors.background
        self.doneButton.setTitleColor(theme.colors.background, for: .normal)
        self.membersLabel.font = theme.fonts.caption1
        self.membersLabel.textColor = theme.colors.tertiaryContent
        self.topicLabel.font = theme.fonts.caption1
        self.topicLabel.textColor = theme.colors.tertiaryContent
        self.userIconView.tintColor = theme.colors.tertiaryContent
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
    
    private func setupViews() {
        let cancelBarButtonItem = MXKBarButtonItem(title: VectorL10n.cancel, style: .plain) { [weak self] in
            self?.cancelButtonAction()
        }
        
        self.navigationItem.rightBarButtonItem = cancelBarButtonItem
        
        self.title = VectorL10n.roomDetailsTitle
        self.doneButton.layer.masksToBounds = true
        self.doneButton.layer.cornerRadius = 8.0
        self.doneButton.setTitle(VectorL10n.join, for: .normal)
    }

    private func render(viewState: ShowSpaceChildRoomDetailViewState) {
        switch viewState {
        case .loading:
            self.renderLoading()
        case .loaded(let roomInfo, let avatarViewData):
            self.renderLoaded(roomInfo: roomInfo, avatarViewData: avatarViewData)
        case .error(let error):
            self.render(error: error)
        }
    }
    
    private func renderLoading() {
        self.activityPresenter.presentActivityIndicator(on: self.view, animated: true)
    }
    
    private func renderLoaded(roomInfo: MXSpaceChildInfo, avatarViewData: AvatarViewData) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        self.titleLabel.text = roomInfo.name
        self.avatarView.fill(with: avatarViewData)
        self.membersLabel.text = "\(roomInfo.activeMemberCount)"
        self.topicLabel.text = roomInfo.topic
    }
    
    private func render(error: Error) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        self.errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
    }

    
    // MARK: - Actions

    @IBAction private func doneButtonAction(_ sender: Any) {
        self.viewModel.process(viewAction: .complete)
    }

    private func cancelButtonAction() {
        self.viewModel.process(viewAction: .cancel)
    }
}


// MARK: - ShowSpaceChildRoomDetailViewModelViewDelegate
extension ShowSpaceChildRoomDetailViewController: ShowSpaceChildRoomDetailViewModelViewDelegate {

    func showSpaceChildRoomDetailViewModel(_ viewModel: ShowSpaceChildRoomDetailViewModelType, didUpdateViewState viewSate: ShowSpaceChildRoomDetailViewState) {
        self.render(viewState: viewSate)
    }
}

// MARK: - SlidingModalPresentable

extension ShowSpaceChildRoomDetailViewController: SlidingModalPresentable {
    
    func allowsDismissOnBackgroundTap() -> Bool {
        return true
    }
    
    func layoutHeightFittingWidth(_ width: CGFloat) -> CGFloat {
        return self.preferredContentSize.height
    }
    
}
