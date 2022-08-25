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

final class KeyBackupSetupPassphraseViewController: UIViewController {
    // MARK: - Constants
    
    private enum Constants {
        static let animationDuration: TimeInterval = 0.3
    }
    
    // MARK: - Properties
    
    // MARK: Outlets

    @IBOutlet private var scrollView: UIScrollView!
    
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var informationLabel: UILabel!
    
    @IBOutlet private var formBackgroundView: UIView!
    
    @IBOutlet private var passphraseTitleLabel: UILabel!
    @IBOutlet private var passphraseTextField: UITextField!
    
    @IBOutlet private var passphraseAdditionalInfoView: UIView!
    @IBOutlet private var passphraseStrengthView: PasswordStrengthView!
    @IBOutlet private var passphraseAdditionalLabel: UILabel!
    
    @IBOutlet private var formSeparatorView: UIView!
    
    @IBOutlet private var confirmPassphraseTitleLabel: UILabel!
    @IBOutlet private var confirmPassphraseTextField: UITextField!
    
    @IBOutlet private var confirmPassphraseAdditionalInfoView: UIView!
    @IBOutlet private var confirmPassphraseAdditionalLabel: UILabel!
    
    @IBOutlet private var setPassphraseButtonBackgroundView: UIView!
    @IBOutlet private var setPassphraseButton: UIButton!
    
    @IBOutlet private var setUpRecoveryKeyInfoLabel: UILabel!
    @IBOutlet private var setUpRecoveryKeyButton: UIButton!
    
    // MARK: Private
    
    private var isFirstViewAppearing = true
    private var isPassphraseTextFieldEditedOnce = false
    private var isConfirmPassphraseTextFieldEditedOnce = false
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
        
        title = VectorL10n.keyBackupSetupTitle
        vc_removeBackTitle()
        
        setupViews()
        keyboardAvoider = KeyboardAvoider(scrollViewContainerView: view, scrollView: scrollView)
        activityPresenter = ActivityIndicatorPresenter()
        errorPresenter = MXKErrorAlertPresentation()
        
        registerThemeServiceDidChangeThemeNotification()
        update(theme: theme)
        
        viewModel.viewDelegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        keyboardAvoider?.startAvoiding()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if isFirstViewAppearing {
            isFirstViewAppearing = false
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        view.endEditing(true)
        keyboardAvoider?.stopAvoiding()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if isFirstViewAppearing {
            // Workaround to layout passphraseStrengthView corner radius
            passphraseStrengthView.setNeedsLayout()
        }
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
        
        titleLabel.textColor = theme.textPrimaryColor
        informationLabel.textColor = theme.textPrimaryColor
        
        formBackgroundView.backgroundColor = theme.backgroundColor
        passphraseTitleLabel.textColor = theme.textPrimaryColor
        theme.applyStyle(onTextField: passphraseTextField)
        passphraseTextField.attributedPlaceholder = NSAttributedString(string: VectorL10n.keyBackupSetupPassphrasePassphrasePlaceholder,
                                                                       attributes: [.foregroundColor: theme.placeholderTextColor])
        updatePassphraseAdditionalLabel()
        
        formSeparatorView.backgroundColor = theme.lineBreakColor
        
        confirmPassphraseTitleLabel.textColor = theme.textPrimaryColor
        theme.applyStyle(onTextField: confirmPassphraseTextField)
        confirmPassphraseTextField.attributedPlaceholder = NSAttributedString(string: VectorL10n.keyBackupSetupPassphraseConfirmPassphraseTitle,
                                                                              attributes: [.foregroundColor: theme.placeholderTextColor])
        updateConfirmPassphraseAdditionalLabel()
        
        setPassphraseButton.backgroundColor = theme.backgroundColor
        theme.applyStyle(onButton: setPassphraseButton)
        
        setUpRecoveryKeyInfoLabel.textColor = theme.textPrimaryColor
        theme.applyStyle(onButton: setUpRecoveryKeyButton)
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
        
        scrollView.keyboardDismissMode = .interactive
        
        titleLabel.text = VectorL10n.keyBackupSetupPassphraseTitle
        informationLabel.text = VectorL10n.keyBackupSetupPassphraseInfo
        
        passphraseTitleLabel.text = VectorL10n.keyBackupSetupPassphrasePassphraseTitle
        passphraseTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        passphraseStrengthView.strength = viewModel.passphraseStrength
        passphraseAdditionalInfoView.isHidden = true
        
        confirmPassphraseTitleLabel.text = VectorL10n.keyBackupSetupPassphraseConfirmPassphraseTitle
        confirmPassphraseTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        confirmPassphraseAdditionalInfoView.isHidden = true
        
        setPassphraseButton.vc_enableMultiLinesTitle()
        setPassphraseButton.setTitle(VectorL10n.keyBackupSetupPassphraseSetPassphraseAction, for: .normal)
        
        updateSetPassphraseButton()
    }
    
    private func showPassphraseAdditionalInfo(animated: Bool) {
        guard passphraseAdditionalInfoView.isHidden else {
            return
        }
        
        UIView.animate(withDuration: Constants.animationDuration) {
            self.passphraseAdditionalInfoView.isHidden = false
        }
    }
    
    private func showConfirmPassphraseAdditionalInfo(animated: Bool) {
        guard confirmPassphraseAdditionalInfoView.isHidden else {
            return
        }
        
        UIView.animate(withDuration: Constants.animationDuration) {
            self.confirmPassphraseAdditionalInfoView.isHidden = false
        }
    }
    
    private func hideConfirmPassphraseAdditionalInfo(animated: Bool) {
        guard confirmPassphraseAdditionalInfoView.isHidden == false else {
            return
        }
        
        UIView.animate(withDuration: Constants.animationDuration) {
            self.confirmPassphraseAdditionalInfoView.isHidden = true
        }
    }
    
    private func updatePassphraseStrengthView() {
        passphraseStrengthView.strength = viewModel.passphraseStrength
    }
    
    private func updatePassphraseAdditionalLabel() {
        let text: String
        let textColor: UIColor
        
        if viewModel.isPassphraseValid {
            text = VectorL10n.keyBackupSetupPassphrasePassphraseValid
            textColor = theme.tintColor
        } else {
            text = VectorL10n.keyBackupSetupPassphrasePassphraseInvalid
            textColor = theme.noticeColor
        }
        
        passphraseAdditionalLabel.text = text
        passphraseAdditionalLabel.textColor = textColor
    }
    
    private func updateConfirmPassphraseAdditionalLabel() {
        let text: String
        let textColor: UIColor
        
        if viewModel.isConfirmPassphraseValid {
            text = VectorL10n.keyBackupSetupPassphraseConfirmPassphraseValid
            textColor = theme.tintColor
        } else {
            text = VectorL10n.keyBackupSetupPassphraseConfirmPassphraseInvalid
            textColor = theme.noticeColor
        }
        
        confirmPassphraseAdditionalLabel.text = text
        confirmPassphraseAdditionalLabel.textColor = textColor
    }
    
    private func updateSetPassphraseButton() {
        setPassphraseButton.isEnabled = viewModel.isFormValid
    }
    
    private func render(viewState: KeyBackupSetupPassphraseViewState) {
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
        hideSkipAlert(animated: false)
        errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
    }
    
    private func showSkipAlert() {
        guard skipAlertController == nil else {
            return
        }
        
        let alertController = UIAlertController(title: VectorL10n.keyBackupSetupSkipAlertTitle,
                                                message: VectorL10n.keyBackupSetupSkipAlertMessage,
                                                preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: VectorL10n.continue, style: .cancel, handler: { _ in
            self.viewModel.process(viewAction: .skipAlertContinue)
        }))
        
        alertController.addAction(UIAlertAction(title: VectorL10n.keyBackupSetupSkipAlertSkipAction, style: .default, handler: { _ in
            self.viewModel.process(viewAction: .skipAlertSkip)
        }))
        
        present(alertController, animated: true, completion: nil)
        skipAlertController = alertController
    }
    
    private func hideSkipAlert(animated: Bool) {
        skipAlertController?.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Actions
    
    @IBAction private func passphraseVisibilityButtonAction(_ sender: Any) {
        guard isPassphraseTextFieldEditedOnce else {
            return
        }
        passphraseTextField.isSecureTextEntry = !passphraseTextField.isSecureTextEntry
        // TODO: Use this when project will be migrated to Swift 4.2
        // self.passphraseTextField.isSecureTextEntry.toggle()
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        if textField == passphraseTextField {
            viewModel.passphrase = textField.text
            
            updatePassphraseAdditionalLabel()
            updatePassphraseStrengthView()
            
            // Show passphrase additional info at first character entered
            if isPassphraseTextFieldEditedOnce == false, textField.text?.isEmpty == false {
                isPassphraseTextFieldEditedOnce = true
                showPassphraseAdditionalInfo(animated: true)
            }
        } else {
            viewModel.confirmPassphrase = textField.text
        }
        
        // Show confirm passphrase additional info if needed
        updateConfirmPassphraseAdditionalLabel()
        if viewModel.confirmPassphrase?.isEmpty == false, viewModel.isPassphraseValid {
            showConfirmPassphraseAdditionalInfo(animated: true)
        } else {
            hideConfirmPassphraseAdditionalInfo(animated: true)
        }
        
        // Enable validate button if form is valid
        updateSetPassphraseButton()
    }
    
    @IBAction private func setPassphraseButtonAction(_ sender: Any) {
        viewModel.process(viewAction: .setupPassphrase)
    }
    
    @IBAction private func setUpRecoveryKeyButtonAction(_ sender: Any) {
        viewModel.process(viewAction: .setupRecoveryKey)
    }
    
    private func cancelButtonAction() {
        viewModel.process(viewAction: .skip)
    }
}

// MARK: - UITextFieldDelegate

extension KeyBackupSetupPassphraseViewController: UITextFieldDelegate {
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        textFieldDidChange(textField)
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == passphraseTextField {
            confirmPassphraseTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        
        return true
    }
}

// MARK: - KeyBackupSetupPassphraseViewModelViewDelegate

extension KeyBackupSetupPassphraseViewController: KeyBackupSetupPassphraseViewModelViewDelegate {
    func keyBackupSetupPassphraseViewModel(_ viewModel: KeyBackupSetupPassphraseViewModelType, didUpdateViewState viewSate: KeyBackupSetupPassphraseViewState) {
        render(viewState: viewSate)
    }
    
    func keyBackupSetupPassphraseViewModelShowSkipAlert(_ viewModel: KeyBackupSetupPassphraseViewModelType) {
        showSkipAlert()
    }
}
