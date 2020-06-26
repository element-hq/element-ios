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

protocol SecureBackupSetupIntroViewControllerDelegate: class {
    func secureBackupSetupIntroViewControllerDidTapUseKey(_ secureBackupSetupIntroViewController: SecureBackupSetupIntroViewController)
    func secureBackupSetupIntroViewControllerDidTapUsePassphrase(_ secureBackupSetupIntroViewController: SecureBackupSetupIntroViewController)
    func secureBackupSetupIntroViewControllerDidCancel(_ secureBackupSetupIntroViewController: SecureBackupSetupIntroViewController)
}

@objcMembers
final class SecureBackupSetupIntroViewController: UIViewController {
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var informationLabel: UILabel!    
    
    @IBOutlet private weak var topSeparatorView: UIView!
    @IBOutlet private weak var secureKeyCell: SecureBackupSetupIntroCell!
    @IBOutlet private weak var securePassphraseCell: SecureBackupSetupIntroCell!
    
    // MARK: Private
    
    private var theme: Theme!
    
    // MARK: Public
    
    weak var delegate: SecureBackupSetupIntroViewControllerDelegate?
    
    // MARK: - Setup
    
    class func instantiate() -> SecureBackupSetupIntroViewController {
        let viewController = StoryboardScene.SecureBackupSetupIntroViewController.initialScene.instantiate()
        viewController.theme = ThemeService.shared().theme
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
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
            guard let self = self else {
                return
            }
            self.delegate?.secureBackupSetupIntroViewControllerDidCancel(self)
        }
        self.navigationItem.rightBarButtonItem = cancelBarButtonItem
        
        self.title = VectorL10n.secureKeyBackupSetupIntroTitle
                
        self.informationLabel.text = VectorL10n.secureKeyBackupSetupIntroInfo
        
        self.secureKeyCell.fill(title: VectorL10n.secureKeyBackupSetupIntroUseSecurityKeyTitle,
                                information: VectorL10n.secureKeyBackupSetupIntroUseSecurityKeyInfo,
                                image: Asset.Images.secretsSetupKey.image)
        
        self.secureKeyCell.action = { [weak self] in
            guard let self = self else {
                return
            }
            self.delegate?.secureBackupSetupIntroViewControllerDidTapUseKey(self)
        }
        
        self.securePassphraseCell.fill(title: VectorL10n.secureKeyBackupSetupIntroUseSecurityPassphraseTitle,
                                information: VectorL10n.secureKeyBackupSetupIntroUseSecurityPassphraseInfo,
                                image: Asset.Images.secretsSetupPassphrase.image)
        
        self.securePassphraseCell.action = { [weak self] in
            guard let self = self else {
                return
            }
            self.delegate?.secureBackupSetupIntroViewControllerDidTapUsePassphrase(self)
        }
    }
    
    private func update(theme: Theme) {
        self.theme = theme
        
        self.view.backgroundColor = theme.headerBackgroundColor
        
        if let navigationBar = self.navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }
        
        self.informationLabel.textColor = theme.textPrimaryColor
        
        self.topSeparatorView.backgroundColor = theme.lineBreakColor
        self.secureKeyCell.update(theme: theme)
        self.securePassphraseCell.update(theme: theme)
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
}
