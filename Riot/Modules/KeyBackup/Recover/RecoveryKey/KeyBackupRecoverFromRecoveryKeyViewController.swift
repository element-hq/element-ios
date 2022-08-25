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

import MobileCoreServices
import UIKit

final class KeyBackupRecoverFromRecoveryKeyViewController: UIViewController {
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private var scrollView: UIScrollView!
    
    @IBOutlet private var shieldImageView: UIImageView!
    
    @IBOutlet private var informationLabel: UILabel!
    
    @IBOutlet private var recoveryKeyTitleLabel: UILabel!
    @IBOutlet private var recoveryKeyTextField: UITextField!
    @IBOutlet private var recoveryKeyTextFieldBackgroundView: UIView!
    
    @IBOutlet private var importFileButton: UIButton!
    
    @IBOutlet private var unknownRecoveryKeyButton: UIButton!
    
    @IBOutlet private var recoverButtonBackgroundView: UIView!
    @IBOutlet private var recoverButton: UIButton!
    
    // MARK: Private
    
    private var viewModel: KeyBackupRecoverFromRecoveryKeyViewModelType!
    private var keyboardAvoider: KeyboardAvoider?
    private var theme: Theme!
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!
    private weak var skipAlertController: UIAlertController?
    
    // MARK: Public
    
    // MARK: - Setup
    
    class func instantiate(with viewModel: KeyBackupRecoverFromRecoveryKeyViewModelType) -> KeyBackupRecoverFromRecoveryKeyViewController {
        let viewController = StoryboardScene.KeyBackupRecoverFromRecoveryKeyViewController.initialScene.instantiate()
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
            self?.cancelButtonAction()
        }
        
        navigationItem.rightBarButtonItem = cancelBarButtonItem
        
        scrollView.keyboardDismissMode = .interactive
        
        let shieldImage = Asset.Images.keyBackupLogo.image.withRenderingMode(.alwaysTemplate)
        shieldImageView.image = shieldImage
        
        informationLabel.text = VectorL10n.keyBackupRecoverFromRecoveryKeyInfo
        
        recoveryKeyTitleLabel.text = VectorL10n.keyBackupRecoverFromRecoveryKeyRecoveryKeyTitle
        recoveryKeyTextField.addTarget(self, action: #selector(recoveryKeyTextFieldDidChange(_:)), for: .editingChanged)
        
        let importFileImage = Asset.Images.importFilesButton.image.withRenderingMode(.alwaysTemplate)
        importFileButton.setImage(importFileImage, for: .normal)
        
        unknownRecoveryKeyButton.vc_enableMultiLinesTitle()
        unknownRecoveryKeyButton.setTitle(VectorL10n.keyBackupRecoverFromRecoveryKeyLostRecoveryKeyAction, for: .normal)
        // Interaction is disabled for the moment
        unknownRecoveryKeyButton.isUserInteractionEnabled = false
        
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
        
        recoveryKeyTextFieldBackgroundView.backgroundColor = theme.backgroundColor
        recoveryKeyTitleLabel.textColor = theme.textPrimaryColor
        theme.applyStyle(onTextField: recoveryKeyTextField)
        recoveryKeyTextField.attributedPlaceholder = NSAttributedString(string: VectorL10n.keyBackupRecoverFromRecoveryKeyRecoveryKeyPlaceholder,
                                                                        attributes: [.foregroundColor: theme.placeholderTextColor])
        
        theme.applyStyle(onButton: importFileButton)
        
        recoverButtonBackgroundView.backgroundColor = theme.backgroundColor
        theme.applyStyle(onButton: recoverButton)
        
        unknownRecoveryKeyButton.setTitleColor(theme.textPrimaryColor, for: .normal)
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
    
    private func render(viewState: KeyBackupRecoverFromRecoveryKeyViewState) {
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
                                        title: VectorL10n.keyBackupRecoverInvalidRecoveryKeyTitle,
                                        message: VectorL10n.keyBackupRecoverInvalidRecoveryKey,
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
            MXLog.debug("Error: \(error)")
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
    
    @IBAction private func usePassphraseButtonAction(_ sender: Any) {
        viewModel.process(viewAction: .recover)
    }
    
    @IBAction private func unknownPassphraseButtonAction(_ sender: Any) {
        viewModel.process(viewAction: .unknownRecoveryKey)
    }
}

// MARK: - UITextFieldDelegate

extension KeyBackupRecoverFromRecoveryKeyViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - KeyBackupRecoverFromRecoveryKeyViewModelViewDelegate

extension KeyBackupRecoverFromRecoveryKeyViewController: KeyBackupRecoverFromRecoveryKeyViewModelViewDelegate {
    func keyBackupRecoverFromPassphraseViewModel(_ viewModel: KeyBackupRecoverFromRecoveryKeyViewModelType, didUpdateViewState viewSate: KeyBackupRecoverFromRecoveryKeyViewState) {
        render(viewState: viewSate)
    }
}

// MARK: - UIDocumentPickerDelegate

extension KeyBackupRecoverFromRecoveryKeyViewController: UIDocumentPickerDelegate {
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
