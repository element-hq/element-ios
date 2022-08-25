// File created from ScreenTemplate
// $ createScreen.sh Spaces/SpaceMembers/MemberDetail ShowSpaceMemberDetail
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

final class SpaceMemberDetailViewController: RoomMemberDetailsViewController {
    // MARK: - Constants
    
    override class func nib() -> UINib! {
        UINib(nibName: "RoomMemberDetailsViewController", bundle: Bundle(for: RoomMemberDetailsViewController.self))
    }
    
    // MARK: - Properties
    
    // MARK: Outlets

    // MARK: Private

    private var viewModel: SpaceMemberDetailViewModelType!
    private var theme: Theme!
    private var keyboardAvoider: KeyboardAvoider?
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!

    // MARK: - Setup
    
    class func instantiate(with viewModel: SpaceMemberDetailViewModelType) -> SpaceMemberDetailViewController {
        let viewController = SpaceMemberDetailViewController()
        viewController.viewModel = viewModel
        viewController.theme = ThemeService.shared().theme
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        setupViews()
        keyboardAvoider = KeyboardAvoider(scrollViewContainerView: view, scrollView: tableView)
        activityPresenter = ActivityIndicatorPresenter()
        errorPresenter = MXKErrorAlertPresentation()
        
        registerThemeServiceDidChangeThemeNotification()
        update(theme: theme)
        
        viewModel.viewDelegate = self
        viewModel.process(viewAction: .loadData)
        
        delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        keyboardAvoider?.startAvoiding()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        keyboardAvoider?.stopAvoiding()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        theme.statusBarStyle
    }
    
    // MARK: - Private
    
    private func update(theme: Theme) {
        self.theme = theme
        
        view.backgroundColor = theme.headerBackgroundColor
        
        if let navigationBar = navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        update(theme: ThemeService.shared().theme)
    }
    
    private func setupViews() {
        if viewModel.showCancelMenuItem {
            let cancelBarButtonItem = MXKBarButtonItem(title: VectorL10n.cancel, style: .plain) { [weak self] in
                self?.cancelButtonAction()
            }
            
            navigationItem.rightBarButtonItem = cancelBarButtonItem
        }
    }

    private func render(viewState: SpaceMemberDetailViewState) {
        switch viewState {
        case .loading:
            renderLoading()
        case .loaded(let member, let space):
            renderLoaded(member: member, space: space)
        case .error(let error):
            render(error: error)
        }
    }
    
    private func renderLoading() {
        activityPresenter.presentActivityIndicator(on: view, animated: true)
    }
    
    private func renderLoaded(member: MXRoomMember, space: MXRoom?) {
        display(member, withMatrixRoom: space)
        activityPresenter.removeCurrentActivityIndicator(animated: true)
    }
    
    private func render(error: Error) {
        activityPresenter.removeCurrentActivityIndicator(animated: true)
        errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
    }
    
    // MARK: - RoomMemberDetailsViewController private

    @objc private func showRoom(withId roomId: String!) {
        viewModel.process(viewAction: .openRoom(roomId))
    }

    // MARK: - Actions

    private func cancelButtonAction() {
        viewModel.process(viewAction: .cancel)
    }
}

// MARK: - SpaceMemberDetailViewModelViewDelegate

extension SpaceMemberDetailViewController: SpaceMemberDetailViewModelViewDelegate {
    func spaceMemberDetailViewModel(_ viewModel: SpaceMemberDetailViewModelType, didUpdateViewState viewSate: SpaceMemberDetailViewState) {
        render(viewState: viewSate)
    }
}

// MARK: - MXKRoomMemberDetailsViewControllerDelegate

extension SpaceMemberDetailViewController: MXKRoomMemberDetailsViewControllerDelegate {
    func roomMemberDetailsViewController(_ roomMemberDetailsViewController: MXKRoomMemberDetailsViewController!, startChatWithMemberId memberId: String!, completion: (() -> Void)!) {
        completion()
        viewModel.process(viewAction: .createRoom(memberId))
    }
}
