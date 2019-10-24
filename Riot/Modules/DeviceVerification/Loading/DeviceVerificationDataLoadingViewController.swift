// File created from ScreenTemplate
// $ createScreen.sh DeviceVerification/Loading DeviceVerificationDataLoading
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

final class DeviceVerificationDataLoadingViewController: UIViewController {
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    // MARK: Private

    private var viewModel: DeviceVerificationDataLoadingViewModelType!
    private var theme: Theme!
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!

    // MARK: - Setup
    
    class func instantiate(with viewModel: DeviceVerificationDataLoadingViewModelType) -> DeviceVerificationDataLoadingViewController {
        let viewController = StoryboardScene.DeviceVerificationDataLoadingViewController.initialScene.instantiate()
        viewController.viewModel = viewModel
        viewController.theme = ThemeService.shared().theme
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        self.title = VectorL10n.deviceVerificationTitle
        self.vc_removeBackTitle()
        
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
    
    // MARK: - Private
    
    private func update(theme: Theme) {
        self.theme = theme
        
        self.view.backgroundColor = theme.headerBackgroundColor
        
        if let navigationBar = self.navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    private func setupViews() {
        let cancelBarButtonItem = MXKBarButtonItem(title: VectorL10n.cancel, style: .plain) { [weak self] in
            self?.cancelButtonAction()
        }
        
        self.navigationItem.rightBarButtonItem = cancelBarButtonItem
    }

    private func render(viewState: DeviceVerificationDataLoadingViewState) {
        switch viewState {
        case .loading:
            self.renderLoading()
        case .loaded:
            self.renderLoaded()
        case .error(let error):
            self.render(error: error)
        case .errorMessage(let message):
            self.renderError(message: message)
        }
    }
    
    private func renderLoading() {
        self.activityPresenter.presentActivityIndicator(on: self.view, animated: true)
    }
    
    private func renderLoaded() {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
    }
    
    private func render(error: Error) {
        self.errorPresenter.presentError(from: self, forError: error, animated: true, handler: {
            self.viewModel.process(viewAction: .cancel)
        })
    }

    private func renderError(message: String) {
        self.errorPresenter.presentError(from: self, title: "", message: message, animated: true, handler: {
            self.viewModel.process(viewAction: .cancel)
        })
    }

    // MARK: - Actions

    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }

    private func cancelButtonAction() {
        self.viewModel.process(viewAction: .cancel)
    }
}


// MARK: - DeviceVerificationDataLoadingViewModelViewDelegate
extension DeviceVerificationDataLoadingViewController: DeviceVerificationDataLoadingViewModelViewDelegate {

    func deviceVerificationDataLoadingViewModel(_ viewModel: DeviceVerificationDataLoadingViewModelType, didUpdateViewState viewSate: DeviceVerificationDataLoadingViewState) {
        self.render(viewState: viewSate)
    }
}
