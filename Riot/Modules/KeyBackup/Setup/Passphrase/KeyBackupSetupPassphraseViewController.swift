/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import UIKit

final class KeyBackupSetupPassphraseViewController: UIViewController {
    
    // MARK: - Constants
    
    private enum Constants {
        static let animationDuration: TimeInterval = 0.3
    }
    
    // MARK: - Properties
    
    // MARK: Outlets

    @IBOutlet private weak var scrollView: UIScrollView!
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var informationLabel: UILabel!
    
    @IBOutlet private weak var formBackgroundView: UIView!
    
    @IBOutlet private weak var passphraseTitleLabel: UILabel!
    @IBOutlet private weak var passphraseTextField: UITextField!
    
    @IBOutlet private weak var passphraseAdditionalInfoView: UIView!
    @IBOutlet private weak var passphraseStrengthView: PasswordStrengthView!
    @IBOutlet private weak var passphraseAdditionalLabel: UILabel!
    
    @IBOutlet private weak var formSeparatorView: UIView!
    
    @IBOutlet private weak var confirmPassphraseTitleLabel: UILabel!
    @IBOutlet private weak var confirmPassphraseTextField: UITextField!
    
    @IBOutlet private weak var confirmPassphraseAdditionalInfoView: UIView!
    @IBOutlet private weak var confirmPassphraseAdditionalLabel: UILabel!
    
    @IBOutlet private weak var setPassphraseButtonBackgroundView: UIView!
    @IBOutlet private weak var setPassphraseButton: UIButton!
    
    @IBOutlet private weak var setUpRecoveryKeyInfoLabel: UILabel!
    @IBOutlet private weak var setUpRecoveryKeyButton: UIButton!
    
    // MARK: Private
    
    private var isFirstViewAppearing: Bool = true
    private var isPassphraseTextFieldEditedOnce: Bool = false
    private var isConfirmPassphraseTextFieldEditedOnce: Bool = false
    private var keyboardAvoider: KeyboardAvoider?
    private var viewModel: KeyBackupSetupPassphraseViewModelType!
    private var theme: Theme!
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!
    private weak var skipAlertController: UIAlertController?
    
    // MARK: - Setup
    
    class func instantiate(with viewModel: KeyBackupSetupPassphraseViewModelType) -> KeyBackupSetupPassphraseViewController {
        let viewController = StoryboardScene.KeyBackupSetupPassphraseViewController.initialScene.instantiate()
        viewController.viewModel = viewModel
        viewController.theme = ThemeService.shared().theme
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        self.title = VectorL10n.keyBackupSetupTitle
        self.vc_removeBackTitle()
        
        self.setupViews()
        self.keyboardAvoider = KeyboardAvoider(scrollViewContainerView: self.view, scrollView: self.scrollView)
        self.activityPresenter = ActivityIndicatorPresenter()
        self.errorPresenter = MXKErrorAlertPresentation()
        
        self.registerThemeServiceDidChangeThemeNotification()
        self.update(theme: self.theme)
        
        self.viewModel.viewDelegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.keyboardAvoider?.startAvoiding()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if self.isFirstViewAppearing {
            self.isFirstViewAppearing = false
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.view.endEditing(true)
        self.keyboardAvoider?.stopAvoiding()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if self.isFirstViewAppearing {
            // Workaround to layout passphraseStrengthView corner radius
            self.passphraseStrengthView.setNeedsLayout()
        }
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
        
        self.titleLabel.textColor = theme.textPrimaryColor
        self.informationLabel.textColor = theme.textPrimaryColor
        
        self.formBackgroundView.backgroundColor = theme.backgroundColor
        self.passphraseTitleLabel.textColor = theme.textPrimaryColor
        theme.applyStyle(onTextField: self.passphraseTextField)
        self.passphraseTextField.attributedPlaceholder = NSAttributedString(string: VectorL10n.keyBackupSetupPassphrasePassphrasePlaceholder,
                                                                            attributes: [.foregroundColor: theme.placeholderTextColor])
        self.updatePassphraseAdditionalLabel()
        
        self.formSeparatorView.backgroundColor = theme.lineBreakColor
        
        self.confirmPassphraseTitleLabel.textColor = theme.textPrimaryColor
        theme.applyStyle(onTextField: self.confirmPassphraseTextField)
        self.confirmPassphraseTextField.attributedPlaceholder = NSAttributedString(string: VectorL10n.keyBackupSetupPassphraseConfirmPassphraseTitle,
                                                                                   attributes: [.foregroundColor: theme.placeholderTextColor])
        self.updateConfirmPassphraseAdditionalLabel()
        
        self.setPassphraseButton.backgroundColor = theme.backgroundColor
        theme.applyStyle(onButton: self.setPassphraseButton)
        
        self.setUpRecoveryKeyInfoLabel.textColor = theme.textPrimaryColor
        theme.applyStyle(onButton: self.setUpRecoveryKeyButton)
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
        
        self.scrollView.keyboardDismissMode = .interactive
        
        self.titleLabel.text = VectorL10n.keyBackupSetupPassphraseTitle
        self.informationLabel.text = VectorL10n.keyBackupSetupPassphraseInfo
        
        self.passphraseTitleLabel.text = VectorL10n.keyBackupSetupPassphrasePassphraseTitle
        self.passphraseTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        self.passphraseStrengthView.strength = self.viewModel.passphraseStrength
        self.passphraseAdditionalInfoView.isHidden = true
        
        self.confirmPassphraseTitleLabel.text = VectorL10n.keyBackupSetupPassphraseConfirmPassphraseTitle
        self.confirmPassphraseTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        self.confirmPassphraseAdditionalInfoView.isHidden = true
        
        self.setPassphraseButton.vc_enableMultiLinesTitle()
        self.setPassphraseButton.setTitle(VectorL10n.keyBackupSetupPassphraseSetPassphraseAction, for: .normal)
        
        self.updateSetPassphraseButton()
    }
    
    private func showPassphraseAdditionalInfo(animated: Bool) {
        guard self.passphraseAdditionalInfoView.isHidden else {
            return
        }
        
        UIView.animate(withDuration: Constants.animationDuration) {
            self.passphraseAdditionalInfoView.isHidden = false
        }
    }
    
    private func showConfirmPassphraseAdditionalInfo(animated: Bool) {
        guard self.confirmPassphraseAdditionalInfoView.isHidden else {
            return
        }
        
        UIView.animate(withDuration: Constants.animationDuration) {
            self.confirmPassphraseAdditionalInfoView.isHidden = false
        }
    }
    
    private func hideConfirmPassphraseAdditionalInfo(animated: Bool) {
        guard self.confirmPassphraseAdditionalInfoView.isHidden == false else {
            return
        }
        
        UIView.animate(withDuration: Constants.animationDuration) {
            self.confirmPassphraseAdditionalInfoView.isHidden = true
        }
    }
    
    private func updatePassphraseStrengthView() {
        self.passphraseStrengthView.strength = self.viewModel.passphraseStrength
    }
    
    private func updatePassphraseAdditionalLabel() {
        
        let text: String
        let textColor: UIColor
        
        if self.viewModel.isPassphraseValid {
            text = VectorL10n.keyBackupSetupPassphrasePassphraseValid
            textColor = self.theme.tintColor
        } else {
            text = VectorL10n.keyBackupSetupPassphrasePassphraseInvalid
            textColor = self.theme.noticeColor
        }
        
        self.passphraseAdditionalLabel.text = text
        self.passphraseAdditionalLabel.textColor = textColor
    }
    
    private func updateConfirmPassphraseAdditionalLabel() {
        
        let text: String
        let textColor: UIColor
        
        if self.viewModel.isConfirmPassphraseValid {
            text = VectorL10n.keyBackupSetupPassphraseConfirmPassphraseValid
            textColor = self.theme.tintColor
        } else {
            text = VectorL10n.keyBackupSetupPassphraseConfirmPassphraseInvalid
            textColor = self.theme.noticeColor
        }
        
        self.confirmPassphraseAdditionalLabel.text = text
        self.confirmPassphraseAdditionalLabel.textColor = textColor
    }
    
    private func updateSetPassphraseButton() {
        self.setPassphraseButton.isEnabled = self.viewModel.isFormValid
    }
    
    private func render(viewState: KeyBackupSetupPassphraseViewState) {
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
        self.hideSkipAlert(animated: false)
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
    
    private func hideSkipAlert(animated: Bool) {
        self.skipAlertController?.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Actions
    
    @IBAction private func passphraseVisibilityButtonAction(_ sender: Any) {
        guard self.isPassphraseTextFieldEditedOnce else {
            return
        }
        self.passphraseTextField.isSecureTextEntry = !self.passphraseTextField.isSecureTextEntry
        // TODO: Use this when project will be migrated to Swift 4.2
        // self.passphraseTextField.isSecureTextEntry.toggle()
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        
        if textField == self.passphraseTextField {
            self.viewModel.passphrase = textField.text
            
            self.updatePassphraseAdditionalLabel()
            self.updatePassphraseStrengthView()
            
            // Show passphrase additional info at first character entered
            if self.isPassphraseTextFieldEditedOnce == false && textField.text?.isEmpty == false {
                self.isPassphraseTextFieldEditedOnce = true
                self.showPassphraseAdditionalInfo(animated: true)
            }
        } else {
            self.viewModel.confirmPassphrase = textField.text
        }
        
        // Show confirm passphrase additional info if needed
        self.updateConfirmPassphraseAdditionalLabel()
        if self.viewModel.confirmPassphrase?.isEmpty == false && self.viewModel.isPassphraseValid {
            self.showConfirmPassphraseAdditionalInfo(animated: true)
        } else {
            self.hideConfirmPassphraseAdditionalInfo(animated: true)
        }
        
        // Enable validate button if form is valid
        self.updateSetPassphraseButton()
    }
    
    @IBAction private func setPassphraseButtonAction(_ sender: Any) {
        self.viewModel.process(viewAction: .setupPassphrase)
    }
    
    @IBAction private func setUpRecoveryKeyButtonAction(_ sender: Any) {
        self.viewModel.process(viewAction: .setupRecoveryKey)
    }
    
    private func cancelButtonAction() {
        self.viewModel.process(viewAction: .skip)
    }
}

// MARK: - UITextFieldDelegate
extension KeyBackupSetupPassphraseViewController: UITextFieldDelegate {
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        self.textFieldDidChange(textField)
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == self.passphraseTextField {
           self.confirmPassphraseTextField.becomeFirstResponder()
        } else {
           textField.resignFirstResponder()
        }
        
        return true
    }
}

// MARK: - KeyBackupSetupPassphraseViewModelViewDelegate
extension KeyBackupSetupPassphraseViewController: KeyBackupSetupPassphraseViewModelViewDelegate {
    func keyBackupSetupPassphraseViewModel(_ viewModel: KeyBackupSetupPassphraseViewModelType, didUpdateViewState viewSate: KeyBackupSetupPassphraseViewState) {
        self.render(viewState: viewSate)
    }
    
    func keyBackupSetupPassphraseViewModelShowSkipAlert(_ viewModel: KeyBackupSetupPassphraseViewModelType) {
        self.showSkipAlert()
    }
}
