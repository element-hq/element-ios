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
    
    @IBOutlet weak var spaceListContainerView: UIView!
    
    // User info
    @IBOutlet private weak var userAvatarView: UserAvatarView!
    @IBOutlet private weak var userDisplayNameLabel: UILabel!
    @IBOutlet private weak var userIdLabel: UILabel!
    
    // Bottom menu items
    
    @IBOutlet private weak var menuItemsStackView: UIStackView!
    
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
        
        navigationController?.setNavigationBarHidden(true, animated: animated)
        screenTracker.trackScreen()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.theme.statusBarStyle
    }
    
    // MARK: - Private
    
    private func update(theme: Theme) {
        self.theme = theme
        
        if let navigationBar = self.navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }
        
        self.view.backgroundColor = theme.colors.background
        
        self.userAvatarView.update(theme: theme)
        self.userDisplayNameLabel.textColor = theme.textPrimaryColor
        self.userDisplayNameLabel.font = theme.fonts.title3SB
        self.userIdLabel.textColor = theme.textSecondaryColor
        
        for sideMenuActionView in self.sideMenuActionViews {
            sideMenuActionView.update(theme: theme)
        }
        
        self.sideMenuVersionView?.update(theme: theme)
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
    
    private func setupViews() {
    }

    private func render(viewState: SideMenuViewState) {
        switch viewState {
        case .loading:
            self.renderLoading()
        case .loaded(let viewData):
            self.renderLoaded(viewData: viewData)
        case .error(let error):
            self.render(error: error)
        }
    }
    
    private func renderLoading() {
        self.activityPresenter.presentActivityIndicator(on: self.view, animated: true)
    }
    
    private func renderLoaded(viewData: SideMenuViewData) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
    
        self.updateUserInformation(with: viewData.userAvatarViewData)
        self.updateBottomMenuItems(with: viewData)
    }
    
    private func updateUserInformation(with userAvatarViewData: UserAvatarViewData) {
        self.userIdLabel.text = userAvatarViewData.userId
        self.userDisplayNameLabel.text = userAvatarViewData.displayName
        self.userDisplayNameLabel.isHidden = userAvatarViewData.displayName.isEmptyOrNil
                
        self.userAvatarView.fill(with: userAvatarViewData)
    }
    
    private func updateBottomMenuItems(with viewData: SideMenuViewData) {
        
        self.menuItemsStackView.vc_removeAllSubviews()
        self.sideMenuActionViews = []
        
        for sideMenuItem in viewData.sideMenuItems {
            let sideMenuActionView = SideMenuActionView.instantiate()
            sideMenuActionView.translatesAutoresizingMaskIntoConstraints = false
            let heightConstraint = sideMenuActionView.heightAnchor.constraint(equalToConstant: 0)
            heightConstraint.priority = .defaultLow
            heightConstraint.isActive = true
            
            sideMenuActionView.update(theme: self.theme)
            sideMenuActionView.fill(with: sideMenuItem)
            sideMenuActionView.delegate = self
            
            self.menuItemsStackView.addArrangedSubview(sideMenuActionView)
            sideMenuActionView.widthAnchor.constraint(equalTo: menuItemsStackView.widthAnchor).isActive = true
            
            self.sideMenuActionViews.append(sideMenuActionView)
        }
        
        if let appVersion = viewData.appVersion {
            let sideMenuVersionView = SideMenuVersionView.instantiate()
            sideMenuVersionView.translatesAutoresizingMaskIntoConstraints = false
            sideMenuVersionView.update(theme: self.theme)
            sideMenuVersionView.fill(with: appVersion)
            
            self.menuItemsStackView.addArrangedSubview(sideMenuVersionView)
            sideMenuVersionView.widthAnchor.constraint(equalTo: menuItemsStackView.widthAnchor).isActive = true
            
            self.sideMenuVersionView = sideMenuVersionView
        }
    }
    
    private func render(error: Error) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        self.errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
    }

    
    // MARK: - Actions
    
    @IBAction func headerTapAction(sender: UIView) {
        self.viewModel.process(viewAction: .tapHeader(sourceView: sender))
    }
}

// MARK: - SideMenuViewModelViewDelegate
extension SideMenuViewController: SideMenuViewModelViewDelegate {

    func sideMenuViewModel(_ viewModel: SideMenuViewModelType, didUpdateViewState viewSate: SideMenuViewState) {
        self.render(viewState: viewSate)
    }
}

// MARK: - SideMenuActionViewDelegate
extension SideMenuViewController: SideMenuActionViewDelegate {
    func sideMenuActionView(_ actionView: SideMenuActionView, didTapMenuItem sideMenuItem: SideMenuItem?) {
        guard let sideMenuItem = sideMenuItem else {
            return
        }
        
        self.viewModel.process(viewAction: .tap(menuItem: sideMenuItem, sourceView: actionView))
    }
}
