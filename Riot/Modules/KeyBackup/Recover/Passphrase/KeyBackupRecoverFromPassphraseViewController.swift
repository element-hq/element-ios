/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import UIKit

final class KeyBackupRecoverFromPassphraseViewController: UIViewController {    
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var scrollView: UIScrollView!
    
    @IBOutlet private weak var shieldImageView: UIImageView!
    
    @IBOutlet private weak var informationLabel: UILabel!        
    
    @IBOutlet private weak var passphraseTitleLabel: UILabel!
    @IBOutlet private weak var passphraseTextField: UITextField!
    @IBOutlet private weak var passphraseTextFieldBackgroundView: UIView!
    
    @IBOutlet private weak var passphraseVisibilityButton: UIButton!
    
    @IBOutlet private weak var unknownPassphraseButton: UIButton!
    
    @IBOutlet private weak var recoverButtonBackgroundView: UIView!
    @IBOutlet private weak var recoverButton: UIButton!
    
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
        
        self.title = VectorL10n.keyBackupRecoverTitle
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
        let cancelBarButtonItem = MXKBarButtonItem(title: VectorL10n.cancel, style: .plain) { [weak self] in
            self?.viewModel.process(viewAction: .cancel)
        }
        
        self.navigationItem.rightBarButtonItem = cancelBarButtonItem
        
        self.scrollView.keyboardDismissMode = .interactive
        
        let shieldImage = Asset.Images.keyBackupLogo.image.withRenderingMode(.alwaysTemplate)
        self.shieldImageView.image = shieldImage
        
        let visibilityImage = Asset.Images.revealPasswordButton.image.withRenderingMode(.alwaysTemplate)
        self.passphraseVisibilityButton.setImage(visibilityImage, for: .normal)
        
        self.informationLabel.text = VectorL10n.keyBackupRecoverFromPassphraseInfo
        
        self.passphraseTitleLabel.text = VectorL10n.keyBackupRecoverFromPassphrasePassphraseTitle
        self.passphraseTextField.addTarget(self, action: #selector(passphraseTextFieldDidChange(_:)), for: .editingChanged)
        
        self.unknownPassphraseButton.vc_enableMultiLinesTitle()
        
        self.recoverButton.vc_enableMultiLinesTitle()
        self.recoverButton.setTitle(VectorL10n.keyBackupRecoverFromPassphraseRecoverAction, for: .normal)
        
        self.updateRecoverButton()
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
        self.passphraseTextField.attributedPlaceholder = NSAttributedString(string: VectorL10n.keyBackupRecoverFromPassphrasePassphrasePlaceholder,
                                                                            attributes: [.foregroundColor: theme.placeholderTextColor])
        
        self.theme.applyStyle(onButton: self.passphraseVisibilityButton)
        
        self.recoverButtonBackgroundView.backgroundColor = theme.backgroundColor
        theme.applyStyle(onButton: self.recoverButton)
        
        let unknownRecoveryKeyAttributedString = NSMutableAttributedString(string: VectorL10n.keyBackupRecoverFromPassphraseLostPassphraseActionPart1, attributes: [.foregroundColor: self.theme.textPrimaryColor])
        let unknownRecoveryKeyAttributedStringPart2 = NSAttributedString(string: VectorL10n.keyBackupRecoverFromPassphraseLostPassphraseActionPart2, attributes: [.foregroundColor: self.theme.tintColor])
        let unknownRecoveryKeyAttributedStringPart3 = NSAttributedString(string: VectorL10n.keyBackupRecoverFromPassphraseLostPassphraseActionPart3, attributes: [.foregroundColor: self.theme.textPrimaryColor])
        
        unknownRecoveryKeyAttributedString.append(unknownRecoveryKeyAttributedStringPart2)
        unknownRecoveryKeyAttributedString.append(unknownRecoveryKeyAttributedStringPart3)
        
        self.unknownPassphraseButton.setAttributedTitle(unknownRecoveryKeyAttributedString, for: .normal)
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
    
    private func render(viewState: KeyBackupRecoverFromPassphraseViewState) {
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

        if (error as NSError).domain == MXKeyBackupErrorDomain
            && (error as NSError).code == Int(MXKeyBackupErrorInvalidRecoveryKeyCode.rawValue) {

            self.errorPresenter.presentError(from: self,
                                             title: VectorL10n.keyBackupRecoverInvalidPassphraseTitle,
                                             message: VectorL10n.keyBackupRecoverInvalidPassphrase,
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
    
    @IBAction private func unknownPassphraseButtonAction(_ sender: Any) {
        self.viewModel.process(viewAction: .unknownPassphrase)
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
        self.render(viewState: viewSate)
    }
}
