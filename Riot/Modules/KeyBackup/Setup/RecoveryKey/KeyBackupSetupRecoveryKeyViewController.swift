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

final class KeyBackupSetupRecoveryKeyViewController: UIViewController {
    
    // MARK: - Constants
    
    private enum Constants {
        static let animationDuration: TimeInterval = 0.3
    }
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var informationLabel: UILabel!
    
    @IBOutlet private weak var recoveryKeyBackgroundView: UIView!
    
    @IBOutlet private weak var recoveryKeyTitleLabel: UILabel!
    @IBOutlet private weak var recoveryKeyLabel: UILabel!
    
    @IBOutlet private weak var separatorView: UIView!
    
    @IBOutlet private weak var makeCopyButton: UIButton!
    
    @IBOutlet private weak var madeCopyButtonBackgroundView: UIView!
    @IBOutlet private weak var madeCopyButton: UIButton!
    
    // MARK: Private
    
    private var theme: Theme!
    private var hasMadeACopy: Bool = false
    private var viewModel: KeyBackupSetupRecoveryKeyViewModelType!
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!
    private weak var skipAlertController: UIAlertController?
    
    // MARK: - Setup
    
    class func instantiate(with viewModel: KeyBackupSetupRecoveryKeyViewModelType) -> KeyBackupSetupRecoveryKeyViewController {
        let viewController = StoryboardScene.KeyBackupSetupRecoveryKeyViewController.initialScene.instantiate()
        viewController.viewModel = viewModel
        viewController.theme = ThemeService.shared().theme
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        self.title = VectorL10n.keyBackupSetupTitle
        
        self.activityPresenter = ActivityIndicatorPresenter()
        self.errorPresenter = MXKErrorAlertPresentation()
        
        self.setupViews()
        self.registerThemeServiceDidChangeThemeNotification()
        self.update(theme: self.theme)
        
        self.viewModel.viewDelegate = self
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
        
        self.informationLabel.textColor = theme.textPrimaryColor

        self.recoveryKeyBackgroundView.backgroundColor = theme.backgroundColor
        
        self.recoveryKeyTitleLabel.textColor = theme.textPrimaryColor
        self.recoveryKeyLabel.textColor = theme.textPrimaryColor
        
        self.separatorView.backgroundColor = theme.lineBreakColor
        
        theme.applyStyle(onButton: self.makeCopyButton)
        
        self.madeCopyButtonBackgroundView.backgroundColor = theme.backgroundColor
        theme.applyStyle(onButton: self.madeCopyButton)
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
    
    private func setupViews() {
        let skipBarButtonItem = MXKBarButtonItem(title: VectorL10n.keyBackupSetupSkipAction, style: .plain) { [weak self] in
            self?.skipButtonAction()
        }
        self.navigationItem.rightBarButtonItem = skipBarButtonItem
        
        self.informationLabel.text = VectorL10n.keyBackupSetupRecoveryKeyInfo
        self.recoveryKeyTitleLabel.text = VectorL10n.keyBackupSetupRecoveryKeyRecoveryKeyTitle
        self.recoveryKeyLabel.text = self.viewModel.recoveryKey
        
        self.makeCopyButton.setTitle(VectorL10n.keyBackupSetupRecoveryKeyMakeCopyAction, for: .normal)
        self.madeCopyButton.setTitle(VectorL10n.keyBackupSetupRecoveryKeyMadeCopyAction, for: .normal)
        
        self.updateMadeCopyButton()
    }
    
    private func shareRecoveryKey() {
        
        // Set up activity view controller
        let activityItems: [Any] = [ self.viewModel.recoveryKey ]
        let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        
        activityViewController.completionWithItemsHandler = { (activityType, completed, returnedItems, error) in
            
            // Enable made copy button only if user has selected an activity item
            if completed {
                self.hasMadeACopy = true
                self.updateMadeCopyButton()
            }
        }
        
        // Configure source view when activity view controller is presented with a popover
        if let popoverPresentationController = activityViewController.popoverPresentationController {
            popoverPresentationController.sourceView = self.makeCopyButton
            popoverPresentationController.sourceRect = self.makeCopyButton.bounds
            popoverPresentationController.permittedArrowDirections = [.down, .up]
        }
        
        self.present(activityViewController, animated: true)
    }
    
    private func updateMadeCopyButton() {
        self.madeCopyButton.isEnabled = self.hasMadeACopy
    }
    
    private func render(viewState: KeyBackupSetupRecoveryKeyViewState) {
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
        self.view.endEditing(true)
        self.activityPresenter.presentActivityIndicator(on: self.view, animated: true)
    }
    
    private func renderLoaded() {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
    }
    
    private func render(error: Error) {
        self.errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
    }
    
    private func showSkipAlert() {
        guard self.skipAlertController == nil else {
            return
        }
        
        let alertController = UIAlertController(title: VectorL10n.keyBackupSetupSkipAlertTitle,
                                                message: VectorL10n.keyBackupSetupSkipAlertMessage,
                                                preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: VectorL10n.continue, style: .cancel, handler: { action in
            self.viewModel.process(viewAction: .skipAlertContinue)
        }))
        
        alertController.addAction(UIAlertAction(title: VectorL10n.keyBackupSetupSkipAlertSkipAction, style: .default, handler: { action in
            self.viewModel.process(viewAction: .skipAlertSkip)
        }))
        
        self.present(alertController, animated: true, completion: nil)
        self.skipAlertController = alertController
    }
    
    // MARK: - Actions
    
    @IBAction private func makeCopyButtonAction(_ sender: Any) {
        self.shareRecoveryKey()
    }
    
    @IBAction private func madeCopyButtonAction(_ sender: Any) {
        self.viewModel.process(viewAction: .madeCopy)
    }
    
    private func skipButtonAction() {
        self.viewModel.process(viewAction: .skip)
    }
}

// MARK: - KeyBackupSetupRecoveryKeyViewModelViewDelegate
extension KeyBackupSetupRecoveryKeyViewController: KeyBackupSetupRecoveryKeyViewModelViewDelegate {
    func keyBackupSetupRecoveryKeyViewModel(_ viewModel: KeyBackupSetupRecoveryKeyViewModelType, didUpdateViewState viewSate: KeyBackupSetupRecoveryKeyViewState) {
        self.render(viewState: viewSate)
    }
    
    func keyBackupSetupPassphraseViewModelShowSkipAlert(_ viewModel: KeyBackupSetupRecoveryKeyViewModelType) {
        self.showSkipAlert()
    }        
}
