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

final class SecretsRecoveryWithPassphraseViewController: UIViewController {
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var scrollView: UIScrollView!
    
    @IBOutlet private weak var shieldImageView: UIImageView!
    
    @IBOutlet private weak var informationLabel: UILabel!        
    
    @IBOutlet private weak var passphraseTitleLabel: UILabel!
    @IBOutlet private weak var passphraseTextField: UITextField!
    @IBOutlet private weak var passphraseTextFieldBackgroundView: UIView!
    
    @IBOutlet private weak var passphraseVisibilityButton: UIButton!
    
    @IBOutlet private weak var useRecoveryKeyButton: UIButton!
        
    @IBOutlet private weak var recoverButton: RoundedButton!
    
    @IBOutlet private weak var resetSecretsButton: UIButton!
    
    // MARK: Private
    
    private var viewModel: SecretsRecoveryWithPassphraseViewModelType!
    private var keyboardAvoider: KeyboardAvoider?
    private var cancellable: Bool!
    private var theme: Theme!
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!
    
    // MARK: Public
    
    // MARK: - Setup
    
    class func instantiate(with viewModel: SecretsRecoveryWithPassphraseViewModelType, cancellable: Bool) -> SecretsRecoveryWithPassphraseViewController {
        let viewController = StoryboardScene.SecretsRecoveryWithPassphraseViewController.initialScene.instantiate()
        viewController.viewModel = viewModel
        viewController.cancellable = cancellable
        viewController.theme = ThemeService.shared().theme
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        self.vc_removeBackTitle()
        
        self.setupViews()
        self.keyboardAvoider = KeyboardAvoider(scrollViewContainerView: self.view, scrollView: self.scrollView)
        self.activityPresenter = ActivityIndicatorPresenter()
        self.errorPresenter = MXKErrorAlertPresentation()
        
        self.registerThemeServiceDidChangeThemeNotification()
        self.update(theme: self.theme)
        
        self.viewModel.viewDelegate = self
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.theme.statusBarStyle
    }
    
    // MARK: - Private
    
    private func setupViews() {
        if self.cancellable {
            let cancelBarButtonItem = MXKBarButtonItem(title: VectorL10n.cancel, style: .plain) { [weak self] in
                self?.viewModel.process(viewAction: .cancel)
            }
            self.navigationItem.rightBarButtonItem = cancelBarButtonItem
        }

        self.title = VectorL10n.secretsRecoveryWithPassphraseTitle
        
        self.scrollView.keyboardDismissMode = .interactive
        
        let shieldImage = Asset.Images.secretsRecoveryPassphrase.image.withRenderingMode(.alwaysTemplate)
        self.shieldImageView.image = shieldImage
        
        let visibilityImage = Asset.Images.revealPasswordButton.image.withRenderingMode(.alwaysTemplate)
        self.passphraseVisibilityButton.setImage(visibilityImage, for: .normal)
        
        let informationText: String        
        
        switch self.viewModel.recoveryGoal {
        case .default, .keyBackup, .restoreSecureBackup:
            informationText = VectorL10n.secretsRecoveryWithPassphraseInformationDefault
        case .unlockSecureBackup:
            informationText = VectorL10n.secretsRecoveryWithKeyInformationUnlockSecureBackupWithPhrase
        case .verifyDevice:
            informationText = VectorL10n.secretsRecoveryWithPassphraseInformationVerifyDevice
        }
        
        self.informationLabel.text = informationText
        
        self.passphraseTitleLabel.text = VectorL10n.secretsRecoveryWithPassphrasePassphraseTitle
        self.passphraseTextField.addTarget(self, action: #selector(passphraseTextFieldDidChange(_:)), for: .editingChanged)
        
        self.useRecoveryKeyButton.vc_enableMultiLinesTitle()
        
        self.recoverButton.vc_enableMultiLinesTitle()
        self.recoverButton.setTitle(VectorL10n.secretsRecoveryWithPassphraseRecoverAction, for: .normal)
        
        self.updateRecoverButton()
                
        self.resetSecretsButton.vc_enableMultiLinesTitle()
        
        self.resetSecretsButton.isHidden = !RiotSettings.shared.secretsRecoveryAllowReset
    }
    
    private func update(theme: Theme) {
        self.theme = theme
        
        self.view.backgroundColor = theme.headerBackgroundColor
        
        if let navigationBar = self.navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }
        
        self.informationLabel.textColor = theme.textPrimaryColor
        
        self.shieldImageView.tintColor = theme.textPrimaryColor
        
        self.passphraseTextFieldBackgroundView.backgroundColor = theme.backgroundColor
        self.passphraseTitleLabel.textColor = theme.textPrimaryColor
        theme.applyStyle(onTextField: self.passphraseTextField)
        self.passphraseTextField.attributedPlaceholder = NSAttributedString(string: VectorL10n.secretsRecoveryWithPassphrasePassphrasePlaceholder,
                                                                            attributes: [.foregroundColor: theme.placeholderTextColor])
        
        self.theme.applyStyle(onButton: self.passphraseVisibilityButton)
        
        self.recoverButton.update(theme: theme)
        
        // Use recovery key button
        
        let useRecoveryKeyAttributedString = NSMutableAttributedString(string: VectorL10n.secretsRecoveryWithPassphraseLostPassphraseActionPart1, attributes: [.foregroundColor: self.theme.textPrimaryColor])
        let unknownRecoveryKeyAttributedStringPart2 = NSAttributedString(string: VectorL10n.secretsRecoveryWithPassphraseLostPassphraseActionPart2, attributes: [.foregroundColor: self.theme.tintColor])
        let unknownRecoveryKeyAttributedStringPart3 = NSAttributedString(string: VectorL10n.secretsRecoveryWithPassphraseLostPassphraseActionPart3, attributes: [.foregroundColor: self.theme.textPrimaryColor])
        
        useRecoveryKeyAttributedString.append(unknownRecoveryKeyAttributedStringPart2)
        useRecoveryKeyAttributedString.append(unknownRecoveryKeyAttributedStringPart3)
        
        self.useRecoveryKeyButton.setAttributedTitle(useRecoveryKeyAttributedString, for: .normal)
        
        // Reset secrets button
        
        let resetSecretsAttributedString = NSMutableAttributedString(string: VectorL10n.secretsRecoveryResetActionPart1, attributes: [.foregroundColor: self.theme.textPrimaryColor])
        let resetSecretsAttributedStringPart2 = NSAttributedString(string: VectorL10n.secretsRecoveryResetActionPart2, attributes: [.foregroundColor: self.theme.warningColor])
        
        resetSecretsAttributedString.append(resetSecretsAttributedStringPart2)
        
        self.resetSecretsButton.setAttributedTitle(resetSecretsAttributedString, for: .normal)
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
    
    private func updateRecoverButton() {
        self.recoverButton.isEnabled = self.viewModel.isFormValid
    }
    
    private func render(viewState: SecretsRecoveryWithPassphraseViewState) {
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
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        
        let nsError = error as NSError
        
        if nsError.domain == MXRecoveryServiceErrorDomain
            && nsError.code == Int(MXRecoveryServiceErrorCode.badRecoveryKeyErrorCode.rawValue) {

            self.errorPresenter.presentError(from: self,
                                             title: VectorL10n.secretsRecoveryWithPassphraseInvalidPassphraseTitle,
                                             message: VectorL10n.secretsRecoveryWithPassphraseInvalidPassphraseMessage,
                                             animated: true,
                                             handler: nil)
        } else {
            self.errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
        }
    }
    
    // MARK: - Actions
    
    @IBAction private func passphraseVisibilityButtonAction(_ sender: Any) {
        self.passphraseTextField.isSecureTextEntry = !self.passphraseTextField.isSecureTextEntry
    }
    
    @objc private func passphraseTextFieldDidChange(_ textField: UITextField) {
        self.viewModel.passphrase = textField.text
        self.updateRecoverButton()
    }
    
    @IBAction private func recoverButtonAction(_ sender: Any) {
        self.viewModel.process(viewAction: .recover)
    }
    
    @IBAction private func useRecoveryKeyButtonAction(_ sender: Any) {
        self.viewModel.process(viewAction: .useRecoveryKey)
    }
    
    
    @IBAction private func resetSecretsAction(_ sender: Any) {
        self.viewModel.process(viewAction: .resetSecrets)
    }
}

// MARK: - UITextFieldDelegate
extension SecretsRecoveryWithPassphraseViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - SecretsRecoveryWithPassphraseViewModelViewDelegate
extension SecretsRecoveryWithPassphraseViewController: SecretsRecoveryWithPassphraseViewModelViewDelegate {
    func secretsRecoveryWithPassphraseViewModel(_ viewModel: SecretsRecoveryWithPassphraseViewModelType, didUpdateViewState viewSate: SecretsRecoveryWithPassphraseViewState) {
        self.render(viewState: viewSate)
    }
}
