/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import UIKit

protocol KeyBackupSetupIntroViewControllerDelegate: AnyObject {
    func keyBackupSetupIntroViewControllerDidTapSetupAction(_ keyBackupSetupIntroViewController: KeyBackupSetupIntroViewController)
    func keyBackupSetupIntroViewControllerDidCancel(_ keyBackupSetupIntroViewController: KeyBackupSetupIntroViewController)
}

final class KeyBackupSetupIntroViewController: UIViewController {
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var keyBackupLogoImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var informationLabel: UILabel!
    
    @IBOutlet private weak var setUpButtonBackgroundView: UIView!
    @IBOutlet private weak var setUpButton: UIButton!
    
    @IBOutlet private weak var manualExportContainerView: UIView!
    @IBOutlet private weak var manualExportInfoLabel: UILabel!
    @IBOutlet private weak var manualExportButton: UIButton!
    
    // MARK: Private
    
    private var theme: Theme!
    private var isABackupAlreadyExists: Bool = false
    private var encryptionKeysExportPresenter: EncryptionKeysExportPresenter?
    
    private var showManualExport: Bool {
        return self.encryptionKeysExportPresenter != nil
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
        
        self.title = VectorL10n.keyBackupSetupTitle
        self.vc_removeBackTitle()
        
        self.setupViews()
        self.registerThemeServiceDidChangeThemeNotification()
        self.update(theme: self.theme)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.theme.statusBarStyle
    }
    
    // MARK: - Private
    
    private func setupViews() {
        let cancelBarButtonItem = MXKBarButtonItem(title: VectorL10n.cancel, style: .plain) { [weak self] in
            self?.showSkipAlert()
        }
        self.navigationItem.rightBarButtonItem = cancelBarButtonItem
        
        let keybackupLogoImage = Asset.Images.keyBackupLogo.image.withRenderingMode(.alwaysTemplate)
        self.keyBackupLogoImageView.image = keybackupLogoImage
        
        self.titleLabel.text = VectorL10n.keyBackupSetupIntroTitle
        self.informationLabel.text = VectorL10n.keyBackupSetupIntroInfo
        
        let setupTitle = self.isABackupAlreadyExists ? VectorL10n.keyBackupSetupIntroSetupConnectActionWithExistingBackup : VectorL10n.keyBackupSetupIntroSetupActionWithoutExistingBackup
        
        self.setUpButton.setTitle(setupTitle, for: .normal)
        
        self.manualExportInfoLabel.text = VectorL10n.keyBackupSetupIntroManualExportInfo
        
        self.manualExportContainerView.isHidden = !self.showManualExport
        self.manualExportButton.setTitle(VectorL10n.keyBackupSetupIntroManualExportAction, for: .normal)
    }
    
    private func update(theme: Theme) {
        self.theme = theme
        
        self.view.backgroundColor = theme.headerBackgroundColor
        
        if let navigationBar = self.navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }
        
        self.keyBackupLogoImageView.tintColor = theme.textPrimaryColor
        
        self.titleLabel.textColor = theme.textPrimaryColor
        self.informationLabel.textColor = theme.textPrimaryColor
        
        self.setUpButtonBackgroundView.backgroundColor = theme.backgroundColor
        theme.applyStyle(onButton: self.setUpButton)
        
        self.manualExportInfoLabel.textColor = theme.textPrimaryColor
        theme.applyStyle(onButton: self.manualExportButton)
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    private func showSkipAlert() {
        let alertController = UIAlertController(title: VectorL10n.keyBackupSetupSkipAlertTitle,
                                                message: VectorL10n.keyBackupSetupSkipAlertMessage,
                                                preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: VectorL10n.continue, style: .cancel, handler: { action in
        }))
        
        alertController.addAction(UIAlertAction(title: VectorL10n.keyBackupSetupSkipAlertSkipAction, style: .default, handler: { action in
            self.delegate?.keyBackupSetupIntroViewControllerDidCancel(self)
        }))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - Actions
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
    
    @IBAction private func validateButtonAction(_ sender: Any) {
        self.delegate?.keyBackupSetupIntroViewControllerDidTapSetupAction(self)
    }
    
    @IBAction private func manualExportButtonAction(_ sender: Any) {
        self.encryptionKeysExportPresenter?.present(from: self, sourceView: self.manualExportButton)
    }
}
