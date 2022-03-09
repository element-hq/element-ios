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

    @IBOutlet private weak var scrollView: UIScrollView!
    
    @IBOutlet private weak var securePassphraseImageView: UIImageView!
    @IBOutlet private weak var informationLabel: UILabel!
    
    @IBOutlet private weak var formBackgroundView: UIView!
    
    @IBOutlet private weak var passphraseTitleLabel: UILabel!
    @IBOutlet private weak var passphraseTextField: UITextField!
    @IBOutlet private weak var passphraseVisibilityButton: UIButton!
    
    @IBOutlet private weak var passphraseAdditionalInfoView: UIView!
    @IBOutlet private weak var passphraseStrengthContainerView: UIView!
    @IBOutlet private weak var passphraseStrengthView: PasswordStrengthView!
    @IBOutlet private weak var passphraseAdditionalLabel: UILabel!
    
    @IBOutlet private weak var additionalInformationLabel: UILabel!
    
    @IBOutlet private weak var validateButton: RoundedButton!
    
    // MARK: Private

    private var viewModel: SecretsSetupRecoveryPassphraseViewModelType!
    private var cancellable: Bool!
    private var theme: Theme!
    private var keyboardAvoider: KeyboardAvoider?
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!
    private var isFirstViewAppearing: Bool = true
    private var isPassphraseTextFieldEditedOnce: Bool = false

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
        
        self.setupViews()
        self.keyboardAvoider = KeyboardAvoider(scrollViewContainerView: self.view, scrollView: self.scrollView)
        self.activityPresenter = ActivityIndicatorPresenter()
        self.errorPresenter = MXKErrorAlertPresentation()
        
        self.registerThemeServiceDidChangeThemeNotification()
        self.update(theme: self.theme)
        
        self.viewModel.viewDelegate = self

        self.viewModel.process(viewAction: .loadData)
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
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.theme.statusBarStyle
    }
    
    // MARK: - Private
    
    private func setupViews() {
        if self.cancellable {
            let cancelBarButtonItem = MXKBarButtonItem(title: VectorL10n.cancel, style: .plain) { [weak self] in
                self?.cancelButtonAction()
            }

            self.navigationItem.rightBarButtonItem = cancelBarButtonItem
        }
        
        self.vc_removeBackTitle()
        
        self.title = VectorL10n.secretsSetupRecoveryPassphraseTitle
        
        self.scrollView.keyboardDismissMode = .interactive
        
        self.securePassphraseImageView.image = Asset.Images.secretsSetupPassphrase.image.withRenderingMode(.alwaysTemplate)
        
        self.passphraseTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        self.passphraseAdditionalInfoView.isHidden = true
        
        let visibilityImage = Asset.Images.revealPasswordButton.image.withRenderingMode(.alwaysTemplate)
        self.passphraseVisibilityButton.setImage(visibilityImage, for: .normal)
        
        self.additionalInformationLabel.text = VectorL10n.secretsSetupRecoveryPassphraseAdditionalInformation
        
        self.validateButton.setTitle(VectorL10n.continue, for: .normal)
    }
    
    private func update(theme: Theme) {
        self.theme = theme
        
        self.view.backgroundColor = theme.headerBackgroundColor
        
        if let navigationBar = self.navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }
        
        self.securePassphraseImageView.tintColor = theme.textPrimaryColor
        
        self.informationLabel.textColor = theme.textPrimaryColor
        
        self.formBackgroundView.backgroundColor = theme.backgroundColor
        self.passphraseTitleLabel.textColor = theme.textPrimaryColor
        theme.applyStyle(onTextField: self.passphraseTextField)
        
        let passphraseTitle: String
            
        if let viewData = self.currentViewData, case .confimPassphrase = viewData.mode {
            passphraseTitle = VectorL10n.secretsSetupRecoveryPassphraseConfirmPassphrasePlaceholder
        } else {
            passphraseTitle = VectorL10n.keyBackupSetupPassphrasePassphrasePlaceholder
        }
        
        self.passphraseTextField.attributedPlaceholder = NSAttributedString(string: passphraseTitle,
                                                                            attributes: [.foregroundColor: theme.placeholderTextColor])
        self.passphraseVisibilityButton.tintColor = theme.tintColor
        
        self.additionalInformationLabel.textColor = theme.textSecondaryColor

        self.validateButton.update(theme: theme)
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }

    private func render(viewState: SecretsSetupRecoveryPassphraseViewState) {
        switch viewState {
        case .loaded(let viewData):
            self.renderLoaded(viewData: viewData)
        case .formUpdated(let viewData):
            self.renderFormUpdated(viewData: viewData)
        case .error(let error):
            self.render(error: error)
        }
    }
    
    private func renderLoaded(viewData: SecretsSetupRecoveryPassphraseViewData) {
        
        self.currentViewData = viewData
        
        let informationText: String
        let passphraseTitle: String
        let showPasswordStrength: Bool
        
        switch viewData.mode {
        case .newPassphrase(strength: let strength):
            informationText = VectorL10n.secretsSetupRecoveryPassphraseInformation
            passphraseTitle = VectorL10n.keyBackupSetupPassphrasePassphraseTitle
            showPasswordStrength = true
            self.passphraseStrengthView.strength = strength
        case .confimPassphrase:
            informationText = VectorL10n.secretsSetupRecoveryPassphraseConfirmInformation
            passphraseTitle = VectorL10n.secretsSetupRecoveryPassphraseConfirmPassphraseTitle
            showPasswordStrength = false
        }
        
        self.informationLabel.text = informationText
        self.passphraseTitleLabel.text = passphraseTitle
        
        self.passphraseStrengthContainerView.isHidden = !showPasswordStrength
        
        self.update(theme: self.theme)
    }
    
    private func renderFormUpdated(viewData: SecretsSetupRecoveryPassphraseViewData) {
        self.currentViewData = viewData
        
        if case .newPassphrase(strength: let strength) = viewData.mode {
            self.passphraseStrengthView.strength = strength
        }
        
        self.validateButton.isEnabled = viewData.isFormValid
        self.updatePassphraseAdditionalLabel(viewData: viewData)
        
        // Show passphrase additional info at first character entered
        if self.isPassphraseTextFieldEditedOnce == false, self.passphraseTextField.text?.isEmpty == false {
            self.isPassphraseTextFieldEditedOnce = true
            self.showPassphraseAdditionalInfo(animated: true)
        }
    }
    
    private func render(error: Error) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        self.errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
    }

    private func showPassphraseAdditionalInfo(animated: Bool) {
        guard self.passphraseAdditionalInfoView.isHidden else {
            return
        }
        
        // Workaround to layout passphraseStrengthView corner radius
        self.passphraseStrengthView.setNeedsLayout()        
        
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
            
            textColor = self.theme.tintColor
        } else {
            switch viewData.mode {
            case .newPassphrase:
                text = VectorL10n.keyBackupSetupPassphrasePassphraseInvalid
            case .confimPassphrase:
                text = VectorL10n.keyBackupSetupPassphraseConfirmPassphraseInvalid
            }
            
            textColor = self.theme.noticeColor
        }
        
        self.passphraseAdditionalLabel.text = text
        self.passphraseAdditionalLabel.textColor = textColor
    }
    
    // MARK: - Actions
    
    @IBAction private func passphraseVisibilityButtonAction(_ sender: Any) {
        guard self.isPassphraseTextFieldEditedOnce else {
            return
        }
        self.passphraseTextField.isSecureTextEntry.toggle()
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        guard textField == self.passphraseTextField else {
            return
        }
        self.viewModel.process(viewAction: .updatePassphrase(textField.text))
    }

    @IBAction private func validateButtonAction(_ sender: Any) {
        self.viewModel.process(viewAction: .validate)
    }

    private func cancelButtonAction() {
        self.viewModel.process(viewAction: .cancel)
    }
}

// MARK: - SecretsSetupRecoveryPassphraseViewModelViewDelegate
extension SecretsSetupRecoveryPassphraseViewController: SecretsSetupRecoveryPassphraseViewModelViewDelegate {

    func secretsSetupRecoveryPassphraseViewModel(_ viewModel: SecretsSetupRecoveryPassphraseViewModelType, didUpdateViewState viewSate: SecretsSetupRecoveryPassphraseViewState) {
        self.render(viewState: viewSate)
    }
}
