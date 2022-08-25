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
    
    @IBOutlet private var scrollView: UIScrollView!
    
    @IBOutlet private var shieldImageView: UIImageView!
    
    @IBOutlet private var informationLabel: UILabel!
    
    @IBOutlet private var passphraseTitleLabel: UILabel!
    @IBOutlet private var passphraseTextField: UITextField!
    @IBOutlet private var passphraseTextFieldBackgroundView: UIView!
    
    @IBOutlet private var passphraseVisibilityButton: UIButton!
    
    @IBOutlet private var useRecoveryKeyButton: UIButton!
        
    @IBOutlet private var recoverButton: RoundedButton!
    
    @IBOutlet private var resetSecretsButton: UIButton!
    
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
        
        vc_removeBackTitle()
        
        setupViews()
        keyboardAvoider = KeyboardAvoider(scrollViewContainerView: view, scrollView: scrollView)
        activityPresenter = ActivityIndicatorPresenter()
        errorPresenter = MXKErrorAlertPresentation()
        
        registerThemeServiceDidChangeThemeNotification()
        update(theme: theme)
        
        viewModel.viewDelegate = self
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        theme.statusBarStyle
    }
    
    // MARK: - Private
    
    private func setupViews() {
        if cancellable {
            let cancelBarButtonItem = MXKBarButtonItem(title: VectorL10n.cancel, style: .plain) { [weak self] in
                self?.viewModel.process(viewAction: .cancel)
            }
            navigationItem.rightBarButtonItem = cancelBarButtonItem
        }

        title = VectorL10n.secretsRecoveryWithPassphraseTitle
        
        scrollView.keyboardDismissMode = .interactive
        
        let shieldImage = Asset.Images.secretsRecoveryPassphrase.image.withRenderingMode(.alwaysTemplate)
        shieldImageView.image = shieldImage
        
        let visibilityImage = Asset.Images.revealPasswordButton.image.withRenderingMode(.alwaysTemplate)
        passphraseVisibilityButton.setImage(visibilityImage, for: .normal)
        
        let informationText: String
        
        switch viewModel.recoveryGoal {
        case .default, .keyBackup, .restoreSecureBackup:
            informationText = VectorL10n.secretsRecoveryWithPassphraseInformationDefault
        case .unlockSecureBackup:
            informationText = VectorL10n.secretsRecoveryWithKeyInformationUnlockSecureBackupWithPhrase
        case .verifyDevice:
            informationText = VectorL10n.secretsRecoveryWithPassphraseInformationVerifyDevice
        }
        
        informationLabel.text = informationText
        
        passphraseTitleLabel.text = VectorL10n.secretsRecoveryWithPassphrasePassphraseTitle
        passphraseTextField.addTarget(self, action: #selector(passphraseTextFieldDidChange(_:)), for: .editingChanged)
        
        useRecoveryKeyButton.vc_enableMultiLinesTitle()
        
        recoverButton.vc_enableMultiLinesTitle()
        recoverButton.setTitle(VectorL10n.secretsRecoveryWithPassphraseRecoverAction, for: .normal)
        
        updateRecoverButton()
                
        resetSecretsButton.vc_enableMultiLinesTitle()
        
        resetSecretsButton.isHidden = !RiotSettings.shared.secretsRecoveryAllowReset
    }
    
    private func update(theme: Theme) {
        self.theme = theme
        
        view.backgroundColor = theme.headerBackgroundColor
        
        if let navigationBar = navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }
        
        informationLabel.textColor = theme.textPrimaryColor
        
        shieldImageView.tintColor = theme.textPrimaryColor
        
        passphraseTextFieldBackgroundView.backgroundColor = theme.backgroundColor
        passphraseTitleLabel.textColor = theme.textPrimaryColor
        theme.applyStyle(onTextField: passphraseTextField)
        passphraseTextField.attributedPlaceholder = NSAttributedString(string: VectorL10n.secretsRecoveryWithPassphrasePassphrasePlaceholder,
                                                                       attributes: [.foregroundColor: theme.placeholderTextColor])
        
        self.theme.applyStyle(onButton: passphraseVisibilityButton)
        
        recoverButton.update(theme: theme)
        
        // Use recovery key button
        
        let useRecoveryKeyAttributedString = NSMutableAttributedString(string: VectorL10n.secretsRecoveryWithPassphraseLostPassphraseActionPart1, attributes: [.foregroundColor: self.theme.textPrimaryColor])
        let unknownRecoveryKeyAttributedStringPart2 = NSAttributedString(string: VectorL10n.secretsRecoveryWithPassphraseLostPassphraseActionPart2, attributes: [.foregroundColor: self.theme.tintColor])
        let unknownRecoveryKeyAttributedStringPart3 = NSAttributedString(string: VectorL10n.secretsRecoveryWithPassphraseLostPassphraseActionPart3, attributes: [.foregroundColor: self.theme.textPrimaryColor])
        
        useRecoveryKeyAttributedString.append(unknownRecoveryKeyAttributedStringPart2)
        useRecoveryKeyAttributedString.append(unknownRecoveryKeyAttributedStringPart3)
        
        useRecoveryKeyButton.setAttributedTitle(useRecoveryKeyAttributedString, for: .normal)
        
        // Reset secrets button
        
        let resetSecretsAttributedString = NSMutableAttributedString(string: VectorL10n.secretsRecoveryResetActionPart1, attributes: [.foregroundColor: self.theme.textPrimaryColor])
        let resetSecretsAttributedStringPart2 = NSAttributedString(string: VectorL10n.secretsRecoveryResetActionPart2, attributes: [.foregroundColor: self.theme.warningColor])
        
        resetSecretsAttributedString.append(resetSecretsAttributedStringPart2)
        
        resetSecretsButton.setAttributedTitle(resetSecretsAttributedString, for: .normal)
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        update(theme: ThemeService.shared().theme)
    }
    
    private func updateRecoverButton() {
        recoverButton.isEnabled = viewModel.isFormValid
    }
    
    private func render(viewState: SecretsRecoveryWithPassphraseViewState) {
        switch viewState {
        case .loading:
            renderLoading()
        case .loaded:
            renderLoaded()
        case .error(let error):
            render(error: error)
        }
    }
    
    private func renderLoading() {
        view.endEditing(true)
        activityPresenter.presentActivityIndicator(on: view, animated: true)
    }
    
    private func renderLoaded() {
        activityPresenter.removeCurrentActivityIndicator(animated: true)
    }
    
    private func render(error: Error) {
        activityPresenter.removeCurrentActivityIndicator(animated: true)
        
        let nsError = error as NSError
        
        if nsError.domain == MXRecoveryServiceErrorDomain,
           nsError.code == Int(MXRecoveryServiceErrorCode.badRecoveryKeyErrorCode.rawValue) {
            errorPresenter.presentError(from: self,
                                        title: VectorL10n.secretsRecoveryWithPassphraseInvalidPassphraseTitle,
                                        message: VectorL10n.secretsRecoveryWithPassphraseInvalidPassphraseMessage,
                                        animated: true,
                                        handler: nil)
        } else {
            errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
        }
    }
    
    // MARK: - Actions
    
    @IBAction private func passphraseVisibilityButtonAction(_ sender: Any) {
        passphraseTextField.isSecureTextEntry = !passphraseTextField.isSecureTextEntry
    }
    
    @objc private func passphraseTextFieldDidChange(_ textField: UITextField) {
        viewModel.passphrase = textField.text
        updateRecoverButton()
    }
    
    @IBAction private func recoverButtonAction(_ sender: Any) {
        viewModel.process(viewAction: .recover)
    }
    
    @IBAction private func useRecoveryKeyButtonAction(_ sender: Any) {
        viewModel.process(viewAction: .useRecoveryKey)
    }
    
    @IBAction private func resetSecretsAction(_ sender: Any) {
        viewModel.process(viewAction: .resetSecrets)
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
        render(viewState: viewSate)
    }
}
