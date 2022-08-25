// File created from ScreenTemplate
// $ createScreen.sh SideMenu SideMenu
/*
 Copyright 2020 New Vector Ltd
 
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

final class SideMenuViewController: UIViewController {
    // MARK: - Constants
    
    private enum Constants {
        static let sideMenuActionViewHeight: CGFloat = 44.0
    }
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet var spaceListContainerView: UIView!
    
    // User info
    @IBOutlet private var userAvatarView: UserAvatarView!
    @IBOutlet private var userDisplayNameLabel: UILabel!
    @IBOutlet private var userIdLabel: UILabel!
    
    // Bottom menu items
    
    @IBOutlet private var menuItemsStackView: UIStackView!
    
    // MARK: Private

    private var viewModel: SideMenuViewModelType!
    private var theme: Theme!
    private var keyboardAvoider: KeyboardAvoider?
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!
    private var screenTracker = AnalyticsScreenTracker(screen: .sidebar)
    
    private var sideMenuActionViews: [SideMenuActionView] = []
    private weak var sideMenuVersionView: SideMenuVersionView?

    // MARK: - Setup
    
    class func instantiate(with viewModel: SideMenuViewModelType) -> SideMenuViewController {
        let viewController = StoryboardScene.SideMenuViewController.initialScene.instantiate()
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
        
        navigationController?.setNavigationBarHidden(true, animated: animated)
        screenTracker.trackScreen()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        theme.statusBarStyle
    }
    
    // MARK: - Private
    
    private func update(theme: Theme) {
        self.theme = theme
        
        if let navigationBar = navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }
        
        view.backgroundColor = theme.colors.background
        
        userAvatarView.update(theme: theme)
        userDisplayNameLabel.textColor = theme.textPrimaryColor
        userDisplayNameLabel.font = theme.fonts.title3SB
        userIdLabel.textColor = theme.textSecondaryColor
        
        for sideMenuActionView in sideMenuActionViews {
            sideMenuActionView.update(theme: theme)
        }
        
        sideMenuVersionView?.update(theme: theme)
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        update(theme: ThemeService.shared().theme)
    }
    
    private func setupViews() { }

    private func render(viewState: SideMenuViewState) {
        switch viewState {
        case .loading:
            renderLoading()
        case .loaded(let viewData):
            renderLoaded(viewData: viewData)
        case .error(let error):
            render(error: error)
        }
    }
    
    private func renderLoading() {
        activityPresenter.presentActivityIndicator(on: view, animated: true)
    }
    
    private func renderLoaded(viewData: SideMenuViewData) {
        activityPresenter.removeCurrentActivityIndicator(animated: true)
    
        updateUserInformation(with: viewData.userAvatarViewData)
        updateBottomMenuItems(with: viewData)
    }
    
    private func updateUserInformation(with userAvatarViewData: UserAvatarViewData) {
        userIdLabel.text = userAvatarViewData.userId
        userDisplayNameLabel.text = userAvatarViewData.displayName
        userDisplayNameLabel.isHidden = userAvatarViewData.displayName.isEmptyOrNil
                
        userAvatarView.fill(with: userAvatarViewData)
    }
    
    private func updateBottomMenuItems(with viewData: SideMenuViewData) {
        menuItemsStackView.vc_removeAllSubviews()
        sideMenuActionViews = []
        
        for sideMenuItem in viewData.sideMenuItems {
            let sideMenuActionView = SideMenuActionView.instantiate()
            sideMenuActionView.translatesAutoresizingMaskIntoConstraints = false
            let heightConstraint = sideMenuActionView.heightAnchor.constraint(equalToConstant: 0)
            heightConstraint.priority = .defaultLow
            heightConstraint.isActive = true
            
            sideMenuActionView.update(theme: theme)
            sideMenuActionView.fill(with: sideMenuItem)
            sideMenuActionView.delegate = self
            
            menuItemsStackView.addArrangedSubview(sideMenuActionView)
            sideMenuActionView.widthAnchor.constraint(equalTo: menuItemsStackView.widthAnchor).isActive = true
            
            sideMenuActionViews.append(sideMenuActionView)
        }
        
        if let appVersion = viewData.appVersion {
            let sideMenuVersionView = SideMenuVersionView.instantiate()
            sideMenuVersionView.translatesAutoresizingMaskIntoConstraints = false
            sideMenuVersionView.update(theme: theme)
            sideMenuVersionView.fill(with: appVersion)
            
            menuItemsStackView.addArrangedSubview(sideMenuVersionView)
            sideMenuVersionView.widthAnchor.constraint(equalTo: menuItemsStackView.widthAnchor).isActive = true
            
            self.sideMenuVersionView = sideMenuVersionView
        }
    }
    
    private func render(error: Error) {
        activityPresenter.removeCurrentActivityIndicator(animated: true)
        errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
    }

    // MARK: - Actions
    
    @IBAction func headerTapAction(sender: UIView) {
        viewModel.process(viewAction: .tapHeader(sourceView: sender))
    }
}

// MARK: - SideMenuViewModelViewDelegate

extension SideMenuViewController: SideMenuViewModelViewDelegate {
    func sideMenuViewModel(_ viewModel: SideMenuViewModelType, didUpdateViewState viewSate: SideMenuViewState) {
        render(viewState: viewSate)
    }
}

// MARK: - SideMenuActionViewDelegate

extension SideMenuViewController: SideMenuActionViewDelegate {
    func sideMenuActionView(_ actionView: SideMenuActionView, didTapMenuItem sideMenuItem: SideMenuItem?) {
        guard let sideMenuItem = sideMenuItem else {
            return
        }
        
        viewModel.process(viewAction: .tap(menuItem: sideMenuItem, sourceView: actionView))
    }
}
