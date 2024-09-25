/*
Copyright 2020-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import UIKit
import MobileCoreServices

final class SecretsRecoveryWithKeyViewController: UIViewController {
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var scrollView: UIScrollView!
    
    @IBOutlet private weak var shieldImageView: UIImageView!
    
    @IBOutlet private weak var informationLabel: UILabel!
    
    @IBOutlet private weak var recoveryKeyTitleLabel: UILabel!
    @IBOutlet private weak var recoveryKeyTextField: UITextField!
    @IBOutlet private weak var recoveryKeyTextFieldBackgroundView: UIView!
    
    @IBOutlet private weak var importFileButton: UIButton!
        
    @IBOutlet private weak var recoverButton: RoundedButton!

    @IBOutlet private weak var resetSecretsButton: UIButton!
    
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
                self?.cancelButtonAction()
            }
            self.navigationItem.rightBarButtonItem = cancelBarButtonItem
        }

        self.title = VectorL10n.secretsRecoveryWithKeyTitle
        
        self.scrollView.keyboardDismissMode = .interactive
        
        let shieldImage = Asset.Images.secretsRecoveryKey.image.withRenderingMode(.alwaysTemplate)
        self.shieldImageView.image = shieldImage
        
        let informationText: String
        
        switch self.viewModel.recoveryGoal {
        case .default, .keyBackup, .restoreSecureBackup:
            informationText = VectorL10n.secretsRecoveryWithKeyInformationDefault
        case .unlockSecureBackup:
            informationText = VectorL10n.secretsRecoveryWithKeyInformationUnlockSecureBackupWithKey
        case .verifyDevice:
            informationText = VectorL10n.secretsRecoveryWithKeyInformationVerifyDevice
        }
        
        self.informationLabel.text = informationText
        
        self.recoveryKeyTitleLabel.text = VectorL10n.secretsRecoveryWithKeyRecoveryKeyTitle
        self.recoveryKeyTextField.addTarget(self, action: #selector(recoveryKeyTextFieldDidChange(_:)), for: .editingChanged)
        
        let importFileImage = Asset.Images.importFilesButton.image.withRenderingMode(.alwaysTemplate)
        self.importFileButton.setImage(importFileImage, for: .normal)
                
        self.recoverButton.vc_enableMultiLinesTitle()
        self.recoverButton.setTitle(VectorL10n.secretsRecoveryWithKeyRecoverAction, for: .normal)
        
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
        
        self.recoveryKeyTextFieldBackgroundView.backgroundColor = theme.backgroundColor
        self.recoveryKeyTitleLabel.textColor = theme.textPrimaryColor
        theme.applyStyle(onTextField: self.recoveryKeyTextField)
        self.recoveryKeyTextField.attributedPlaceholder = NSAttributedString(string: VectorL10n.secretsRecoveryWithKeyRecoveryKeyPlaceholder,
                                                                            attributes: [.foregroundColor: theme.placeholderTextColor])
        theme.applyStyle(onButton: self.importFileButton)
        
        self.recoverButton.update(theme: theme)
        
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
    
    private func render(viewState: SecretsRecoveryWithKeyViewState) {
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
            && (nsError.code == Int(MXRecoveryServiceErrorCode.badRecoveryKeyErrorCode.rawValue)
                || nsError.code == Int(MXRecoveryServiceErrorCode.badRecoveryKeyFormatErrorCode.rawValue)
            ) {

            self.errorPresenter.presentError(from: self,
                                             title: VectorL10n.secretsRecoveryWithKeyInvalidRecoveryKeyTitle,
                                             message: VectorL10n.secretsRecoveryWithKeyInvalidRecoveryKeyMessage,
                                             animated: true,
                                             handler: nil)
        } else {
            self.errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
        }
    }
    
    private func showFileSelection() {
        // Show only text documents
        let documentPicker = UIDocumentPickerViewController(documentTypes: [kUTTypeText as String], in: .import)
        documentPicker.delegate = self
        self.present(documentPicker, animated: true, completion: nil)
    }
    
    private func importRecoveryKey(from url: URL) {
        if let recoveryKey = self.getDocumentContent(from: url) {
            self.recoveryKeyTextField.text = recoveryKey
            self.recoveryKeyTextFieldDidChange(self.recoveryKeyTextField)
        } else {
            self.errorPresenter.presentGenericError(from: self, animated: true, handler: nil)
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
        self.viewModel.process(viewAction: .cancel)
    }
    
    @IBAction private func importFileButtonAction(_ sender: Any) {
        self.showFileSelection()
    }
    
    @objc private func recoveryKeyTextFieldDidChange(_ textField: UITextField) {
        self.viewModel.recoveryKey = textField.text
        self.updateRecoverButton()
    }        
    
    @IBAction private func recoverButtonAction(_ sender: Any) {
        self.viewModel.process(viewAction: .recover)
    }
    
    @IBAction private func resetSecretsAction(_ sender: Any) {
        self.viewModel.process(viewAction: .resetSecrets)
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
        self.render(viewState: viewSate)
    }
}

// MARK: - UIDocumentPickerDelegate
extension SecretsRecoveryWithKeyViewController: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let documentUrl = urls.first else {
            return
        }
        self.importRecoveryKey(from: documentUrl)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        self.importRecoveryKey(from: url)
    }
}
