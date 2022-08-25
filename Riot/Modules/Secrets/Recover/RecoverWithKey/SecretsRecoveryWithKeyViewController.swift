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

import MobileCoreServices
import UIKit

final class SecretsRecoveryWithKeyViewController: UIViewController {
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private var scrollView: UIScrollView!
    
    @IBOutlet private var shieldImageView: UIImageView!
    
    @IBOutlet private var informationLabel: UILabel!
    
    @IBOutlet private var recoveryKeyTitleLabel: UILabel!
    @IBOutlet private var recoveryKeyTextField: UITextField!
    @IBOutlet private var recoveryKeyTextFieldBackgroundView: UIView!
    
    @IBOutlet private var importFileButton: UIButton!
        
    @IBOutlet private var recoverButton: RoundedButton!

    @IBOutlet private var resetSecretsButton: UIButton!
    
    // MARK: Private
    
    private var viewModel: SecretsRecoveryWithKeyViewModelType!
    private var keyboardAvoider: KeyboardAvoider?
    private var cancellable: Bool!
    private var theme: Theme!
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!
    private weak var skipAlertController: UIAlertController?
    
    // MARK: Public
    
    // MARK: - Setup
    
    class func instantiate(with viewModel: SecretsRecoveryWithKeyViewModelType, cancellable: Bool) -> SecretsRecoveryWithKeyViewController {
        let viewController = StoryboardScene.SecretsRecoveryWithKeyViewController.initialScene.instantiate()
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
                self?.cancelButtonAction()
            }
            navigationItem.rightBarButtonItem = cancelBarButtonItem
        }

        title = VectorL10n.secretsRecoveryWithKeyTitle
        
        scrollView.keyboardDismissMode = .interactive
        
        let shieldImage = Asset.Images.secretsRecoveryKey.image.withRenderingMode(.alwaysTemplate)
        shieldImageView.image = shieldImage
        
        let informationText: String
        
        switch viewModel.recoveryGoal {
        case .default, .keyBackup, .restoreSecureBackup:
            informationText = VectorL10n.secretsRecoveryWithKeyInformationDefault
        case .unlockSecureBackup:
            informationText = VectorL10n.secretsRecoveryWithKeyInformationUnlockSecureBackupWithKey
        case .verifyDevice:
            informationText = VectorL10n.secretsRecoveryWithKeyInformationVerifyDevice
        }
        
        informationLabel.text = informationText
        
        recoveryKeyTitleLabel.text = VectorL10n.secretsRecoveryWithKeyRecoveryKeyTitle
        recoveryKeyTextField.addTarget(self, action: #selector(recoveryKeyTextFieldDidChange(_:)), for: .editingChanged)
        
        let importFileImage = Asset.Images.importFilesButton.image.withRenderingMode(.alwaysTemplate)
        importFileButton.setImage(importFileImage, for: .normal)
                
        recoverButton.vc_enableMultiLinesTitle()
        recoverButton.setTitle(VectorL10n.secretsRecoveryWithKeyRecoverAction, for: .normal)
        
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
        
        recoveryKeyTextFieldBackgroundView.backgroundColor = theme.backgroundColor
        recoveryKeyTitleLabel.textColor = theme.textPrimaryColor
        theme.applyStyle(onTextField: recoveryKeyTextField)
        recoveryKeyTextField.attributedPlaceholder = NSAttributedString(string: VectorL10n.secretsRecoveryWithKeyRecoveryKeyPlaceholder,
                                                                        attributes: [.foregroundColor: theme.placeholderTextColor])
        theme.applyStyle(onButton: importFileButton)
        
        recoverButton.update(theme: theme)
        
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
    
    private func render(viewState: SecretsRecoveryWithKeyViewState) {
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
           nsError.code == Int(MXRecoveryServiceErrorCode.badRecoveryKeyErrorCode.rawValue)
           || nsError.code == Int(MXRecoveryServiceErrorCode.badRecoveryKeyFormatErrorCode.rawValue)
        {
            errorPresenter.presentError(from: self,
                                        title: VectorL10n.secretsRecoveryWithKeyInvalidRecoveryKeyTitle,
                                        message: VectorL10n.secretsRecoveryWithKeyInvalidRecoveryKeyMessage,
                                        animated: true,
                                        handler: nil)
        } else {
            errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
        }
    }
    
    private func showFileSelection() {
        // Show only text documents
        let documentPicker = UIDocumentPickerViewController(documentTypes: [kUTTypeText as String], in: .import)
        documentPicker.delegate = self
        present(documentPicker, animated: true, completion: nil)
    }
    
    private func importRecoveryKey(from url: URL) {
        if let recoveryKey = getDocumentContent(from: url) {
            recoveryKeyTextField.text = recoveryKey
            recoveryKeyTextFieldDidChange(recoveryKeyTextField)
        } else {
            errorPresenter.presentGenericError(from: self, animated: true, handler: nil)
        }
    }
    
    private func getDocumentContent(from documentURL: URL) -> String? {
        let documentContent: String?
        
        do {
            documentContent = try String(contentsOf: documentURL)
        } catch {
            MXLog.debug("[SecretsRecoveryWithKeyViewController] Error: \(error)")
            documentContent = nil
        }
        
        return documentContent
    }
    
    // MARK: - Actions
    
    private func cancelButtonAction() {
        viewModel.process(viewAction: .cancel)
    }
    
    @IBAction private func importFileButtonAction(_ sender: Any) {
        showFileSelection()
    }
    
    @objc private func recoveryKeyTextFieldDidChange(_ textField: UITextField) {
        viewModel.recoveryKey = textField.text
        updateRecoverButton()
    }
    
    @IBAction private func recoverButtonAction(_ sender: Any) {
        viewModel.process(viewAction: .recover)
    }
    
    @IBAction private func resetSecretsAction(_ sender: Any) {
        viewModel.process(viewAction: .resetSecrets)
    }
}

// MARK: - UITextFieldDelegate

extension SecretsRecoveryWithKeyViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - SecretsRecoveryWithKeyViewModelViewDelegate

extension SecretsRecoveryWithKeyViewController: SecretsRecoveryWithKeyViewModelViewDelegate {
    func secretsRecoveryWithKeyViewModel(_ viewModel: SecretsRecoveryWithKeyViewModelType, didUpdateViewState viewSate: SecretsRecoveryWithKeyViewState) {
        render(viewState: viewSate)
    }
}

// MARK: - UIDocumentPickerDelegate

extension SecretsRecoveryWithKeyViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let documentUrl = urls.first else {
            return
        }
        importRecoveryKey(from: documentUrl)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        importRecoveryKey(from: url)
    }
}
