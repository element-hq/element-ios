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

    @IBOutlet private weak var scrollView: UIScrollView!
    
    @IBOutlet private weak var warningImage: UIImageView!
            
    @IBOutlet private weak var informationLabel: UILabel!
    
    @IBOutlet private weak var warningTitle: UILabel!
    @IBOutlet private weak var warningMessage: UILabel!
    
    @IBOutlet private weak var resetButton: RoundedButton!
    
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
        
        self.warningImage.tintColor = theme.warningColor
        
        self.informationLabel.textColor = theme.textPrimaryColor
        
        self.warningTitle.textColor = theme.warningColor
        self.warningMessage.textColor = theme.textPrimaryColor

        self.resetButton.update(theme: theme)
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
        
        self.title = VectorL10n.secretsResetTitle
        
        self.scrollView.keyboardDismissMode = .interactive
        
        self.informationLabel.text = VectorL10n.secretsResetInformation
        
        self.warningTitle.text = VectorL10n.secretsResetWarningTitle
        self.warningMessage.text = VectorL10n.secretsResetWarningMessage
        
        self.resetButton.setTitle(VectorL10n.secretsResetResetAction, for: .normal)
    }

    private func render(viewState: SecretsResetViewState) {
        switch viewState {
        case .resetting:
            self.renderLoading()
        case .resetDone:
            self.renderLoaded()
        case .resetCancelled:
            self.renderCancelled()
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
    
    private func renderCancelled() {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
    }
    
    private func render(error: Error) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        self.errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
    }
    
    // MARK: - Actions

    private func cancelButtonAction() {
        self.viewModel.process(viewAction: .cancel)
    }
    
    @IBAction private func resetAction(_ sender: Any) {
        self.viewModel.process(viewAction: .reset)
    }    
}


// MARK: - SecretsResetViewModelViewDelegate
extension SecretsResetViewController: SecretsResetViewModelViewDelegate {

    func secretsResetViewModel(_ viewModel: SecretsResetViewModelType, didUpdateViewState viewSate: SecretsResetViewState) {
        self.render(viewState: viewSate)
    }
}
