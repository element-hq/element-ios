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

protocol SecureBackupSetupIntroViewControllerDelegate: AnyObject {
    func secureBackupSetupIntroViewControllerDidTapUseKey(_ secureBackupSetupIntroViewController: SecureBackupSetupIntroViewController)
    func secureBackupSetupIntroViewControllerDidTapUsePassphrase(_ secureBackupSetupIntroViewController: SecureBackupSetupIntroViewController)
    func secureBackupSetupIntroViewControllerDidCancel(_ secureBackupSetupIntroViewController: SecureBackupSetupIntroViewController, showSkipAlert: Bool)
    func secureBackupSetupIntroViewControllerDidTapConnectToKeyBackup(_ secureBackupSetupIntroViewController: SecureBackupSetupIntroViewController)
}

@objcMembers
final class SecureBackupSetupIntroViewController: UIViewController {
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private var informationLabel: UILabel!
    
    @IBOutlet private var topSeparatorView: UIView!
    @IBOutlet private var secureKeyCell: SecureBackupSetupIntroCell!
    @IBOutlet private var securePassphraseCell: SecureBackupSetupIntroCell!
    
    // MARK: Private
    
    private var viewModel: SecureBackupSetupIntroViewModelType!
    private var cancellable: Bool!
    private var theme: Theme!
    
    private var activityIndicatorPresenter: ActivityIndicatorPresenter!
    private var errorPresenter: MXKErrorPresentation!
    
    // MARK: Public
    
    weak var delegate: SecureBackupSetupIntroViewControllerDelegate?
        
    // MARK: - Setup
    
    class func instantiate(with viewModel: SecureBackupSetupIntroViewModelType, cancellable: Bool) -> SecureBackupSetupIntroViewController {
        let viewController = StoryboardScene.SecureBackupSetupIntroViewController.initialScene.instantiate()
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
        activityIndicatorPresenter = ActivityIndicatorPresenter()
        errorPresenter = MXKErrorAlertPresentation()
        
        registerThemeServiceDidChangeThemeNotification()
        update(theme: theme)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkKeyBackup()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        theme.statusBarStyle
    }
    
    // MARK: - Private
    
    private func setupViews() {
        if cancellable {
            let cancelBarButtonItem = MXKBarButtonItem(title: VectorL10n.cancel, style: .plain) { [weak self] in
                guard let self = self else {
                    return
                }
                self.delegate?.secureBackupSetupIntroViewControllerDidCancel(self, showSkipAlert: true)
            }
            navigationItem.rightBarButtonItem = cancelBarButtonItem
        }
        
        title = VectorL10n.secureKeyBackupSetupIntroTitle
                
        informationLabel.text = VectorL10n.secureKeyBackupSetupIntroInfo
        
        secureKeyCell.fill(title: VectorL10n.secureKeyBackupSetupIntroUseSecurityKeyTitle,
                           information: VectorL10n.secureKeyBackupSetupIntroUseSecurityKeyInfo,
                           image: Asset.Images.secretsSetupKey.image)
        
        secureKeyCell.action = { [weak self] in
            guard let self = self else {
                return
            }
            self.delegate?.secureBackupSetupIntroViewControllerDidTapUseKey(self)
        }
        
        securePassphraseCell.fill(title: VectorL10n.secureKeyBackupSetupIntroUseSecurityPassphraseTitle,
                                  information: VectorL10n.secureKeyBackupSetupIntroUseSecurityPassphraseInfo,
                                  image: Asset.Images.secretsSetupPassphrase.image)
        
        securePassphraseCell.action = { [weak self] in
            guard let self = self else {
                return
            }
            self.delegate?.secureBackupSetupIntroViewControllerDidTapUsePassphrase(self)
        }

        setupBackupMethods()
    }

    private func setupBackupMethods() {
        let secureBackupSetupMethods = viewModel.homeserverEncryptionConfiguration.secureBackupSetupMethods

        // Hide setup methods that are not listed
        if !secureBackupSetupMethods.contains(.key) {
            secureKeyCell.isHidden = true
        }

        if !secureBackupSetupMethods.contains(.passphrase) {
            securePassphraseCell.isHidden = true
        }
    }
    
    private func renderLoading() {
        activityIndicatorPresenter.presentActivityIndicator(on: view, animated: true)
    }
    
    private func renderLoaded() {
        activityIndicatorPresenter.removeCurrentActivityIndicator(animated: true)
    }
    
    private func render(error: Error) {
        activityIndicatorPresenter.removeCurrentActivityIndicator(animated: true)
        errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
    }
    
    private func update(theme: Theme) {
        self.theme = theme
        
        view.backgroundColor = theme.headerBackgroundColor
        
        if let navigationBar = navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }
        
        informationLabel.textColor = theme.textPrimaryColor
        
        topSeparatorView.backgroundColor = theme.lineBreakColor
        secureKeyCell.update(theme: theme)
        securePassphraseCell.update(theme: theme)
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        update(theme: ThemeService.shared().theme)
    }
    
    // TODO: To remove
    private func checkKeyBackup() {
        guard viewModel.checkKeyBackup else {
            return
        }
        
        guard let keyBackup = viewModel.keyBackup else {
            return
        }
        
        // If a backup already exists and we do not have the private key,
        // we need to get this private key first. Ask the user to make a key backup restore to catch it
        if keyBackup.keyBackupVersion != nil, keyBackup.hasPrivateKeyInCryptoStore == false {
            let alertController = UIAlertController(title: VectorL10n.secureKeyBackupSetupExistingBackupErrorTitle,
                                                    message: VectorL10n.secureKeyBackupSetupExistingBackupErrorInfo,
                                                    preferredStyle: .alert)

            let connectAction = UIAlertAction(title: VectorL10n.secureKeyBackupSetupExistingBackupErrorUnlockIt, style: .default) { _ in
                self.delegate?.secureBackupSetupIntroViewControllerDidTapConnectToKeyBackup(self)
            }
            
            let resetAction = UIAlertAction(title: VectorL10n.secureKeyBackupSetupExistingBackupErrorDeleteIt, style: .destructive) { _ in
                self.deleteKeybackup()
            }
            
            let cancelAction = UIAlertAction(title: VectorL10n.cancel, style: .cancel) { _ in
                self.delegate?.secureBackupSetupIntroViewControllerDidCancel(self, showSkipAlert: false)
            }
            
            alertController.addAction(connectAction)
            alertController.addAction(resetAction)
            alertController.addAction(cancelAction)
            
            present(alertController, animated: true)
        }
    }
    
    // TODO: Move to view model
    private func deleteKeybackup() {
        guard let keyBackup = viewModel.keyBackup, let keybackupVersion = keyBackup.keyBackupVersion?.version else {
            return
        }
        
        renderLoading()
        keyBackup.deleteVersion(keybackupVersion, success: { [weak self] in
            guard let self = self else {
                return
            }
            self.renderLoaded()
            self.checkKeyBackup()
        }, failure: { [weak self] error in
            guard let self = self else {
                return
            }
            
            self.render(error: error)
        })
    }
}
