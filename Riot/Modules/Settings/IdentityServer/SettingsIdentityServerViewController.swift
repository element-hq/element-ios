// File created from ScreenTemplate
// $ createScreen.sh Test SettingsIdentityServer
/*
 Copyright 2019 New Vector Ltd
 
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

final class SettingsIdentityServerViewController: UIViewController {    
    
    // MARK: - Properties
    
    // MARK: Outlets

    @IBOutlet private weak var scrollView: UIScrollView!
    
    @IBOutlet private weak var messageLabel: UILabel!
    @IBOutlet private weak var addOrChangeButton: UIButton!
    
    // MARK: Private

    private var viewModel: SettingsIdentityServerViewModelType!
    private var theme: Theme!
    private var keyboardAvoider: KeyboardAvoider?
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!
    private var viewState: SettingsIdentityServerViewState?
    
    private var displayMode: SettingsIdentityServerDisplayMode?

    // MARK: - Setup
    
    class func instantiate(with viewModel: SettingsIdentityServerViewModelType) -> SettingsIdentityServerViewController {
        let viewController = StoryboardScene.SettingsIdentityServerViewController.initialScene.instantiate()
        viewController.viewModel = viewModel
        viewController.theme = ThemeService.shared().theme
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        self.title = "Identity server"
        
        self.setupViews()
        self.keyboardAvoider = KeyboardAvoider(scrollViewContainerView: self.view, scrollView: self.scrollView)
        self.activityPresenter = ActivityIndicatorPresenter()
        self.errorPresenter = MXKErrorAlertPresentation()
        
        self.registerThemeServiceDidChangeThemeNotification()
        self.update(theme: self.theme)
        
        self.viewModel.viewDelegate = self

        self.viewModel.process(viewAction: .load)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.keyboardAvoider?.startAvoiding()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.keyboardAvoider?.stopAvoiding()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.theme.statusBarStyle
    }
    
    // MARK: - Private
    
    private func update(theme: Theme) {
        self.theme = theme
        
        self.view.backgroundColor = theme.headerBackgroundColor
        
        if let navigationBar = self.navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }

        // TODO:
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
    
    private func setupViews() {
        self.scrollView.keyboardDismissMode = .interactive
    }

    private func render(viewState: SettingsIdentityServerViewState) {
        switch viewState {
        case .loading:
            self.renderLoading()
        case .loaded:
            self.renderLoaded()
        case .error(let error):
            self.render(error: error)
        }
    }
    
    private func renderLoading() {
        self.activityPresenter.presentActivityIndicator(on: self.view, animated: true)
    }
    
    private func renderLoaded() {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
    }
    
    private func render(error: Error) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        self.errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
    }

    func presentExistingIdentityServerDataAlert(with title: String) {
        
    }
    
    // MARK: - Actions

    @IBAction private func addOrChangeButtonAction(_ sender: Any) {
        guard let displayMode = self.displayMode else {
            return
        }
        
        let identityServer = "TODO"
        
        let viewAction: SettingsIdentityServerViewAction?
        
        switch displayMode {
        case .noIdentityServer:
            viewAction = .add(identityServer: identityServer)
        case .identityServer:
            viewAction = .change(identityServer: identityServer)
        default:
            viewAction = nil
        }
        
        if let viewAction = viewAction {
            self.viewModel.process(viewAction: viewAction)
        }
    }
}


// MARK: - SettingsIdentityServerViewModelViewDelegate
extension SettingsIdentityServerViewController: SettingsIdentityServerViewModelViewDelegate {

    func settingsIdentityServerViewModel(_ viewModel: SettingsIdentityServerViewModelType, didUpdateViewState viewState: SettingsIdentityServerViewState) {
        self.viewState = viewState
        self.render(viewState: viewState)
    }
}
