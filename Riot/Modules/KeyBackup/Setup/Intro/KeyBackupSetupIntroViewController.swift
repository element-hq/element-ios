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

protocol KeyBackupSetupIntroViewControllerDelegate: AnyObject {
    func keyBackupSetupIntroViewControllerDidTapSetupAction(_ keyBackupSetupIntroViewController: KeyBackupSetupIntroViewController)
    func keyBackupSetupIntroViewControllerDidCancel(_ keyBackupSetupIntroViewController: KeyBackupSetupIntroViewController)
}

final class KeyBackupSetupIntroViewController: UIViewController {
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private var keyBackupLogoImageView: UIImageView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var informationLabel: UILabel!
    
    @IBOutlet private var setUpButtonBackgroundView: UIView!
    @IBOutlet private var setUpButton: UIButton!
    
    @IBOutlet private var manualExportContainerView: UIView!
    @IBOutlet private var manualExportInfoLabel: UILabel!
    @IBOutlet private var manualExportButton: UIButton!
    
    // MARK: Private
    
    private var theme: Theme!
    private var isABackupAlreadyExists = false
    private var encryptionKeysExportPresenter: EncryptionKeysExportPresenter?
    
    private var showManualExport: Bool {
        self.encryptionKeysExportPresenter != nil
    }
    
    // MARK: Public
    
    weak var delegate: KeyBackupSetupIntroViewControllerDelegate?
    
    // MARK: - Setup
    
    class func instantiate(isABackupAlreadyExists: Bool, encryptionKeysExportPresenter: EncryptionKeysExportPresenter?) -> KeyBackupSetupIntroViewController {
        let viewController = StoryboardScene.KeyBackupSetupIntroViewController.initialScene.instantiate()
        viewController.theme = ThemeService.shared().theme
        viewController.isABackupAlreadyExists = isABackupAlreadyExists
        viewController.encryptionKeysExportPresenter = encryptionKeysExportPresenter
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        title = VectorL10n.keyBackupSetupTitle
        vc_removeBackTitle()
        
        setupViews()
        registerThemeServiceDidChangeThemeNotification()
        update(theme: theme)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        theme.statusBarStyle
    }
    
    // MARK: - Private
    
    private func setupViews() {
        let cancelBarButtonItem = MXKBarButtonItem(title: VectorL10n.cancel, style: .plain) { [weak self] in
            self?.showSkipAlert()
        }
        navigationItem.rightBarButtonItem = cancelBarButtonItem
        
        let keybackupLogoImage = Asset.Images.keyBackupLogo.image.withRenderingMode(.alwaysTemplate)
        keyBackupLogoImageView.image = keybackupLogoImage
        
        titleLabel.text = VectorL10n.keyBackupSetupIntroTitle
        informationLabel.text = VectorL10n.keyBackupSetupIntroInfo
        
        let setupTitle = isABackupAlreadyExists ? VectorL10n.keyBackupSetupIntroSetupConnectActionWithExistingBackup : VectorL10n.keyBackupSetupIntroSetupActionWithoutExistingBackup
        
        setUpButton.setTitle(setupTitle, for: .normal)
        
        manualExportInfoLabel.text = VectorL10n.keyBackupSetupIntroManualExportInfo
        
        manualExportContainerView.isHidden = !showManualExport
        manualExportButton.setTitle(VectorL10n.keyBackupSetupIntroManualExportAction, for: .normal)
    }
    
    private func update(theme: Theme) {
        self.theme = theme
        
        view.backgroundColor = theme.headerBackgroundColor
        
        if let navigationBar = navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }
        
        keyBackupLogoImageView.tintColor = theme.textPrimaryColor
        
        titleLabel.textColor = theme.textPrimaryColor
        informationLabel.textColor = theme.textPrimaryColor
        
        setUpButtonBackgroundView.backgroundColor = theme.backgroundColor
        theme.applyStyle(onButton: setUpButton)
        
        manualExportInfoLabel.textColor = theme.textPrimaryColor
        theme.applyStyle(onButton: manualExportButton)
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    private func showSkipAlert() {
        let alertController = UIAlertController(title: VectorL10n.keyBackupSetupSkipAlertTitle,
                                                message: VectorL10n.keyBackupSetupSkipAlertMessage,
                                                preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: VectorL10n.continue, style: .cancel, handler: { _ in
        }))
        
        alertController.addAction(UIAlertAction(title: VectorL10n.keyBackupSetupSkipAlertSkipAction, style: .default, handler: { _ in
            self.delegate?.keyBackupSetupIntroViewControllerDidCancel(self)
        }))
        
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - Actions
    
    @objc private func themeDidChange() {
        update(theme: ThemeService.shared().theme)
    }
    
    @IBAction private func validateButtonAction(_ sender: Any) {
        delegate?.keyBackupSetupIntroViewControllerDidTapSetupAction(self)
    }
    
    @IBAction private func manualExportButtonAction(_ sender: Any) {
        encryptionKeysExportPresenter?.present(from: self, sourceView: manualExportButton)
    }
}
