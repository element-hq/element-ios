// File created from ScreenTemplate
// $ createScreen.sh Test SecretsSetupRecoveryPassphrase
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

final class SecretsSetupRecoveryPassphraseViewController: UIViewController {
    // MARK: - Constants
    
    private enum Constants {
        static let animationDuration: TimeInterval = 0.3
    }
    
    // MARK: - Properties
    
    // MARK: Outlets

    @IBOutlet private var scrollView: UIScrollView!
    
    @IBOutlet private var securePassphraseImageView: UIImageView!
    @IBOutlet private var informationLabel: UILabel!
    
    @IBOutlet private var formBackgroundView: UIView!
    
    @IBOutlet private var passphraseTitleLabel: UILabel!
    @IBOutlet private var passphraseTextField: UITextField!
    @IBOutlet private var passphraseVisibilityButton: UIButton!
    
    @IBOutlet private var passphraseAdditionalInfoView: UIView!
    @IBOutlet private var passphraseStrengthContainerView: UIView!
    @IBOutlet private var passphraseStrengthView: PasswordStrengthView!
    @IBOutlet private var passphraseAdditionalLabel: UILabel!
    
    @IBOutlet private var additionalInformationLabel: UILabel!
    
    @IBOutlet private var validateButton: RoundedButton!
    
    // MARK: Private

    private var viewModel: SecretsSetupRecoveryPassphraseViewModelType!
    private var cancellable: Bool!
    private var theme: Theme!
    private var keyboardAvoider: KeyboardAvoider?
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!
    private var isFirstViewAppearing = true
    private var isPassphraseTextFieldEditedOnce = false

    private var currentViewData: SecretsSetupRecoveryPassphraseViewData?
    
    // MARK: - Setup
    
    class func instantiate(with viewModel: SecretsSetupRecoveryPassphraseViewModelType, cancellable: Bool) -> SecretsSetupRecoveryPassphraseViewController {
        let viewController = StoryboardScene.SecretsSetupRecoveryPassphraseViewController.initialScene.instantiate()
        viewController.viewModel = viewModel
        viewController.cancellable = cancellable
        viewController.theme = ThemeService.shared().theme
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        setupViews()
        keyboardAvoider = KeyboardAvoider(scrollViewContainerView: view, scrollView: scrollView)
        activityPresenter = ActivityIndicatorPresenter()
        errorPresenter = MXKErrorAlertPresentation()
        
        registerThemeServiceDidChangeThemeNotification()
        update(theme: theme)
        
        viewModel.viewDelegate = self

        viewModel.process(viewAction: .loadData)
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
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        theme.statusBarStyle
    }
    
    // MARK: - Private
    
    private func setupViews() {
        if cancellable {
            let cancelBarButtonItem = MXKBarButtonItem(title: VectorL10n.cancel, style: .plain) { [weak self] in
                self?.cancelButtonAction()
            }

            navigationItem.rightBarButtonItem = cancelBarButtonItem
        }
        
        vc_removeBackTitle()
        
        title = VectorL10n.secretsSetupRecoveryPassphraseTitle
        
        scrollView.keyboardDismissMode = .interactive
        
        securePassphraseImageView.image = Asset.Images.secretsSetupPassphrase.image.withRenderingMode(.alwaysTemplate)
        
        passphraseTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        passphraseAdditionalInfoView.isHidden = true
        
        let visibilityImage = Asset.Images.revealPasswordButton.image.withRenderingMode(.alwaysTemplate)
        passphraseVisibilityButton.setImage(visibilityImage, for: .normal)
        
        additionalInformationLabel.text = VectorL10n.secretsSetupRecoveryPassphraseAdditionalInformation
        
        validateButton.setTitle(VectorL10n.continue, for: .normal)
    }
    
    private func update(theme: Theme) {
        self.theme = theme
        
        view.backgroundColor = theme.headerBackgroundColor
        
        if let navigationBar = navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }
        
        securePassphraseImageView.tintColor = theme.textPrimaryColor
        
        informationLabel.textColor = theme.textPrimaryColor
        
        formBackgroundView.backgroundColor = theme.backgroundColor
        passphraseTitleLabel.textColor = theme.textPrimaryColor
        theme.applyStyle(onTextField: passphraseTextField)
        
        let passphraseTitle: String
            
        if let viewData = currentViewData, case .confimPassphrase = viewData.mode {
            passphraseTitle = VectorL10n.secretsSetupRecoveryPassphraseConfirmPassphrasePlaceholder
        } else {
            passphraseTitle = VectorL10n.keyBackupSetupPassphrasePassphrasePlaceholder
        }
        
        passphraseTextField.attributedPlaceholder = NSAttributedString(string: passphraseTitle,
                                                                       attributes: [.foregroundColor: theme.placeholderTextColor])
        passphraseVisibilityButton.tintColor = theme.tintColor
        
        additionalInformationLabel.textColor = theme.textSecondaryColor

        validateButton.update(theme: theme)
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        update(theme: ThemeService.shared().theme)
    }

    private func render(viewState: SecretsSetupRecoveryPassphraseViewState) {
        switch viewState {
        case .loaded(let viewData):
            renderLoaded(viewData: viewData)
        case .formUpdated(let viewData):
            renderFormUpdated(viewData: viewData)
        case .error(let error):
            render(error: error)
        }
    }
    
    private func renderLoaded(viewData: SecretsSetupRecoveryPassphraseViewData) {
        currentViewData = viewData
        
        let informationText: String
        let passphraseTitle: String
        let showPasswordStrength: Bool
        
        switch viewData.mode {
        case .newPassphrase(strength: let strength):
            informationText = VectorL10n.secretsSetupRecoveryPassphraseInformation
            passphraseTitle = VectorL10n.keyBackupSetupPassphrasePassphraseTitle
            showPasswordStrength = true
            passphraseStrengthView.strength = strength
        case .confimPassphrase:
            informationText = VectorL10n.secretsSetupRecoveryPassphraseConfirmInformation
            passphraseTitle = VectorL10n.secretsSetupRecoveryPassphraseConfirmPassphraseTitle
            showPasswordStrength = false
        }
        
        informationLabel.text = informationText
        passphraseTitleLabel.text = passphraseTitle
        
        passphraseStrengthContainerView.isHidden = !showPasswordStrength
        
        update(theme: theme)
    }
    
    private func renderFormUpdated(viewData: SecretsSetupRecoveryPassphraseViewData) {
        currentViewData = viewData
        
        if case .newPassphrase(strength: let strength) = viewData.mode {
            self.passphraseStrengthView.strength = strength
        }
        
        validateButton.isEnabled = viewData.isFormValid
        updatePassphraseAdditionalLabel(viewData: viewData)
        
        // Show passphrase additional info at first character entered
        if isPassphraseTextFieldEditedOnce == false, passphraseTextField.text?.isEmpty == false {
            isPassphraseTextFieldEditedOnce = true
            showPassphraseAdditionalInfo(animated: true)
        }
    }
    
    private func render(error: Error) {
        activityPresenter.removeCurrentActivityIndicator(animated: true)
        errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
    }

    private func showPassphraseAdditionalInfo(animated: Bool) {
        guard passphraseAdditionalInfoView.isHidden else {
            return
        }
        
        // Workaround to layout passphraseStrengthView corner radius
        passphraseStrengthView.setNeedsLayout()
        
        UIView.animate(withDuration: Constants.animationDuration) {
            self.passphraseAdditionalInfoView.isHidden = false
        }
    }
    
    private func updatePassphraseAdditionalLabel(viewData: SecretsSetupRecoveryPassphraseViewData) {
        let text: String
        let textColor: UIColor
        
        if viewData.isFormValid {
            switch viewData.mode {
            case .newPassphrase:
                text = VectorL10n.keyBackupSetupPassphrasePassphraseValid
            case .confimPassphrase:
                text = VectorL10n.keyBackupSetupPassphraseConfirmPassphraseValid
            }
            
            textColor = theme.tintColor
        } else {
            switch viewData.mode {
            case .newPassphrase:
                text = VectorL10n.keyBackupSetupPassphrasePassphraseInvalid
            case .confimPassphrase:
                text = VectorL10n.keyBackupSetupPassphraseConfirmPassphraseInvalid
            }
            
            textColor = theme.noticeColor
        }
        
        passphraseAdditionalLabel.text = text
        passphraseAdditionalLabel.textColor = textColor
    }
    
    // MARK: - Actions
    
    @IBAction private func passphraseVisibilityButtonAction(_ sender: Any) {
        guard isPassphraseTextFieldEditedOnce else {
            return
        }
        passphraseTextField.isSecureTextEntry.toggle()
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        guard textField == passphraseTextField else {
            return
        }
        viewModel.process(viewAction: .updatePassphrase(textField.text))
    }

    @IBAction private func validateButtonAction(_ sender: Any) {
        viewModel.process(viewAction: .validate)
    }

    private func cancelButtonAction() {
        viewModel.process(viewAction: .cancel)
    }
}

// MARK: - SecretsSetupRecoveryPassphraseViewModelViewDelegate

extension SecretsSetupRecoveryPassphraseViewController: SecretsSetupRecoveryPassphraseViewModelViewDelegate {
    func secretsSetupRecoveryPassphraseViewModel(_ viewModel: SecretsSetupRecoveryPassphraseViewModelType, didUpdateViewState viewSate: SecretsSetupRecoveryPassphraseViewState) {
        render(viewState: viewSate)
    }
}
