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

final class KeyBackupRecoverFromPassphraseViewController: UIViewController {
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private var scrollView: UIScrollView!
    
    @IBOutlet private var shieldImageView: UIImageView!
    
    @IBOutlet private var informationLabel: UILabel!
    
    @IBOutlet private var passphraseTitleLabel: UILabel!
    @IBOutlet private var passphraseTextField: UITextField!
    @IBOutlet private var passphraseTextFieldBackgroundView: UIView!
    
    @IBOutlet private var passphraseVisibilityButton: UIButton!
    
    @IBOutlet private var unknownPassphraseButton: UIButton!
    
    @IBOutlet private var recoverButtonBackgroundView: UIView!
    @IBOutlet private var recoverButton: UIButton!
    
    // MARK: Private
    
    private var viewModel: KeyBackupRecoverFromPassphraseViewModelType!
    private var keyboardAvoider: KeyboardAvoider?
    private var theme: Theme!
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!
    
    // MARK: Public
    
    // MARK: - Setup
    
    class func instantiate(with viewModel: KeyBackupRecoverFromPassphraseViewModelType) -> KeyBackupRecoverFromPassphraseViewController {
        let viewController = StoryboardScene.KeyBackupRecoverFromPassphraseViewController.initialScene.instantiate()
        viewController.viewModel = viewModel
        viewController.theme = ThemeService.shared().theme
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        title = VectorL10n.keyBackupRecoverTitle
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
        let cancelBarButtonItem = MXKBarButtonItem(title: VectorL10n.cancel, style: .plain) { [weak self] in
            self?.viewModel.process(viewAction: .cancel)
        }
        
        navigationItem.rightBarButtonItem = cancelBarButtonItem
        
        scrollView.keyboardDismissMode = .interactive
        
        let shieldImage = Asset.Images.keyBackupLogo.image.withRenderingMode(.alwaysTemplate)
        shieldImageView.image = shieldImage
        
        let visibilityImage = Asset.Images.revealPasswordButton.image.withRenderingMode(.alwaysTemplate)
        passphraseVisibilityButton.setImage(visibilityImage, for: .normal)
        
        informationLabel.text = VectorL10n.keyBackupRecoverFromPassphraseInfo
        
        passphraseTitleLabel.text = VectorL10n.keyBackupRecoverFromPassphrasePassphraseTitle
        passphraseTextField.addTarget(self, action: #selector(passphraseTextFieldDidChange(_:)), for: .editingChanged)
        
        unknownPassphraseButton.vc_enableMultiLinesTitle()
        
        recoverButton.vc_enableMultiLinesTitle()
        recoverButton.setTitle(VectorL10n.keyBackupRecoverFromPassphraseRecoverAction, for: .normal)
        
        updateRecoverButton()
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
        passphraseTextField.attributedPlaceholder = NSAttributedString(string: VectorL10n.keyBackupRecoverFromPassphrasePassphrasePlaceholder,
                                                                       attributes: [.foregroundColor: theme.placeholderTextColor])
        
        self.theme.applyStyle(onButton: passphraseVisibilityButton)
        
        recoverButtonBackgroundView.backgroundColor = theme.backgroundColor
        theme.applyStyle(onButton: recoverButton)
        
        let unknownRecoveryKeyAttributedString = NSMutableAttributedString(string: VectorL10n.keyBackupRecoverFromPassphraseLostPassphraseActionPart1, attributes: [.foregroundColor: self.theme.textPrimaryColor])
        let unknownRecoveryKeyAttributedStringPart2 = NSAttributedString(string: VectorL10n.keyBackupRecoverFromPassphraseLostPassphraseActionPart2, attributes: [.foregroundColor: self.theme.tintColor])
        let unknownRecoveryKeyAttributedStringPart3 = NSAttributedString(string: VectorL10n.keyBackupRecoverFromPassphraseLostPassphraseActionPart3, attributes: [.foregroundColor: self.theme.textPrimaryColor])
        
        unknownRecoveryKeyAttributedString.append(unknownRecoveryKeyAttributedStringPart2)
        unknownRecoveryKeyAttributedString.append(unknownRecoveryKeyAttributedStringPart3)
        
        unknownPassphraseButton.setAttributedTitle(unknownRecoveryKeyAttributedString, for: .normal)
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
    
    private func render(viewState: KeyBackupRecoverFromPassphraseViewState) {
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

        if (error as NSError).domain == MXKeyBackupErrorDomain,
           (error as NSError).code == Int(MXKeyBackupErrorInvalidRecoveryKeyCode.rawValue) {
            errorPresenter.presentError(from: self,
                                        title: VectorL10n.keyBackupRecoverInvalidPassphraseTitle,
                                        message: VectorL10n.keyBackupRecoverInvalidPassphrase,
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
    
    @IBAction private func unknownPassphraseButtonAction(_ sender: Any) {
        viewModel.process(viewAction: .unknownPassphrase)
    }
}

// MARK: - UITextFieldDelegate

extension KeyBackupRecoverFromPassphraseViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - KeyBackupRecoverFromPassphraseViewModelViewDelegate

extension KeyBackupRecoverFromPassphraseViewController: KeyBackupRecoverFromPassphraseViewModelViewDelegate {
    func keyBackupRecoverFromPassphraseViewModel(_ viewModel: KeyBackupRecoverFromPassphraseViewModelType, didUpdateViewState viewSate: KeyBackupRecoverFromPassphraseViewState) {
        render(viewState: viewSate)
    }
}
