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

protocol KeyBackupSetupIntroViewControllerDelegate: class {
    func keyBackupSetupIntroViewControllerDidTapSetupAction(_ keyBackupSetupIntroViewController: KeyBackupSetupIntroViewController)
    func keyBackupSetupIntroViewControllerDidCancel(_ keyBackupSetupIntroViewController: KeyBackupSetupIntroViewController)
}

final class KeyBackupSetupIntroViewController: UIViewController {
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var informationLabel: UILabel!
    
    @IBOutlet private weak var setUpButtonBackgroundView: UIView!
    @IBOutlet private weak var setUpButton: UIButton!
    
    // MARK: Private
    
    private var theme: Theme!
    
    // MARK: Public
    
    weak var delegate: KeyBackupSetupIntroViewControllerDelegate?
    
    // MARK: - Setup
    
    class func instantiate() -> KeyBackupSetupIntroViewController {
        let viewController = StoryboardScene.KeyBackupSetupIntroViewController.initialScene.instantiate()
        viewController.theme = ThemeService.shared().theme
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
        let cancelBarButtonItem = MXKBarButtonItem(title: VectorL10n.keyBackupSetupSkipAction, style: .plain) { [weak self] in
            if let sself = self {
                sself.delegate?.keyBackupSetupIntroViewControllerDidCancel(sself)
            }
        }
        self.navigationItem.rightBarButtonItem = cancelBarButtonItem
        
        self.titleLabel.text = VectorL10n.keyBackupSetupIntroTitle
        self.informationLabel.text = VectorL10n.keyBackupSetupIntroInfo
        self.setUpButton.setTitle(VectorL10n.keyBackupSetupIntroSetupAction, for: .normal)
    }
    
    private func update(theme: Theme) {
        self.theme = theme
        
        self.view.backgroundColor = theme.headerBackgroundColor
        
        if let navigationBar = self.navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }
        
        self.titleLabel.textColor = theme.textPrimaryColor
        self.informationLabel.textColor = theme.textPrimaryColor
        
        self.setUpButtonBackgroundView.backgroundColor = theme.backgroundColor
        theme.applyStyle(onButton: self.setUpButton)
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    // MARK: - Actions
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
    
    @IBAction private func validateButtonAction(_ sender: Any) {
        self.delegate?.keyBackupSetupIntroViewControllerDidTapSetupAction(self)
    }
}
