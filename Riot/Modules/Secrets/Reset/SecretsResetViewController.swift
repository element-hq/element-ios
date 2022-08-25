// File created from ScreenTemplate
// $ createScreen.sh Secrets/Reset SecretsReset
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

final class SecretsResetViewController: UIViewController {
    // MARK: - Constants
    
    // MARK: - Properties
    
    // MARK: Outlets

    @IBOutlet private var scrollView: UIScrollView!
    
    @IBOutlet private var warningImage: UIImageView!
            
    @IBOutlet private var informationLabel: UILabel!
    
    @IBOutlet private var warningTitle: UILabel!
    @IBOutlet private var warningMessage: UILabel!
    
    @IBOutlet private var resetButton: RoundedButton!
    
    // MARK: Private

    private var viewModel: SecretsResetViewModelType!
    private var theme: Theme!
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!
    
    // MARK: - Setup
    
    class func instantiate(with viewModel: SecretsResetViewModelType) -> SecretsResetViewController {
        let viewController = StoryboardScene.SecretsResetViewController.initialScene.instantiate()
        viewController.viewModel = viewModel
        viewController.theme = ThemeService.shared().theme
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        vc_removeBackTitle()
        
        setupViews()
        activityPresenter = ActivityIndicatorPresenter()
        errorPresenter = MXKErrorAlertPresentation()
        
        registerThemeServiceDidChangeThemeNotification()
        update(theme: theme)
        
        viewModel.viewDelegate = self

        viewModel.process(viewAction: .loadData)
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
        
        warningImage.tintColor = theme.warningColor
        
        informationLabel.textColor = theme.textPrimaryColor
        
        warningTitle.textColor = theme.warningColor
        warningMessage.textColor = theme.textPrimaryColor

        resetButton.update(theme: theme)
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        update(theme: ThemeService.shared().theme)
    }
    
    private func setupViews() {
        let cancelBarButtonItem = MXKBarButtonItem(title: VectorL10n.cancel, style: .plain) { [weak self] in
            self?.cancelButtonAction()
        }
        
        navigationItem.rightBarButtonItem = cancelBarButtonItem
        
        title = VectorL10n.secretsResetTitle
        
        scrollView.keyboardDismissMode = .interactive
        
        informationLabel.text = VectorL10n.secretsResetInformation
        
        warningTitle.text = VectorL10n.secretsResetWarningTitle
        warningMessage.text = VectorL10n.secretsResetWarningMessage
        
        resetButton.setTitle(VectorL10n.secretsResetResetAction, for: .normal)
    }

    private func render(viewState: SecretsResetViewState) {
        switch viewState {
        case .resetting:
            renderLoading()
        case .resetDone:
            renderLoaded()
        case .error(let error):
            render(error: error)
        }
    }
    
    private func renderLoading() {
        activityPresenter.presentActivityIndicator(on: view, animated: true)
    }
    
    private func renderLoaded() {
        activityPresenter.removeCurrentActivityIndicator(animated: true)
    }
    
    private func render(error: Error) {
        activityPresenter.removeCurrentActivityIndicator(animated: true)
        errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
    }
    
    // MARK: - Actions

    private func cancelButtonAction() {
        viewModel.process(viewAction: .cancel)
    }
    
    @IBAction private func resetAction(_ sender: Any) {
        viewModel.process(viewAction: .reset)
    }
}

// MARK: - SecretsResetViewModelViewDelegate

extension SecretsResetViewController: SecretsResetViewModelViewDelegate {
    func secretsResetViewModel(_ viewModel: SecretsResetViewModelType, didUpdateViewState viewSate: SecretsResetViewState) {
        render(viewState: viewSate)
    }
}
