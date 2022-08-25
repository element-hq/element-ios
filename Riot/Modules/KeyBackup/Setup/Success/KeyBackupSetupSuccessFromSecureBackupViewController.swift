/*
 Copyright 2021 New Vector Ltd
 
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

protocol KeyBackupSetupSuccessFromSecureBackupViewControllerDelegate: AnyObject {
    func keyBackupSetupSuccessFromSecureBackupViewControllerDidTapDoneAction(_ viewController: KeyBackupSetupSuccessFromSecureBackupViewController)
}

final class KeyBackupSetupSuccessFromSecureBackupViewController: UIViewController {
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private var keyBackupLogoImageView: UIImageView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var informationLabel: UILabel!
    
    @IBOutlet private var doneButtonBackgroundView: UIView!
    @IBOutlet private var doneButton: UIButton!
    
    // MARK: Private
    
    private var theme: Theme!
    
    // MARK: Public
    
    weak var delegate: KeyBackupSetupSuccessFromSecureBackupViewControllerDelegate?
    
    // MARK: - Setup
    
    class func instantiate() -> KeyBackupSetupSuccessFromSecureBackupViewController {
        let viewController = StoryboardScene.KeyBackupSetupSuccessFromSecureBackupViewController.initialScene.instantiate()
        viewController.theme = ThemeService.shared().theme
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        title = VectorL10n.keyBackupSetupTitle
        
        setupViews()
        registerThemeServiceDidChangeThemeNotification()
        update(theme: theme)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide back button
        navigationItem.setHidesBackButton(true, animated: animated)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        theme.statusBarStyle
    }
    
    // MARK: - Private
    
    private func setupViews() {
        let keybackupLogoImage = Asset.Images.keyBackupLogo.image.withRenderingMode(.alwaysTemplate)
        keyBackupLogoImageView.image = keybackupLogoImage
        
        titleLabel.text = VectorL10n.keyBackupSetupSuccessTitle
        informationLabel.text = VectorL10n.keyBackupSetupSuccessFromSecureBackupInfo
        
        doneButton.setTitle(VectorL10n.keyBackupSetupSuccessFromPassphraseDoneAction, for: .normal)
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
        
        doneButtonBackgroundView.backgroundColor = theme.backgroundColor
        theme.applyStyle(onButton: doneButton)
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        update(theme: ThemeService.shared().theme)
    }
    
    // MARK: - Actions
    
    @IBAction private func doneButtonAction(_ sender: Any) {
        delegate?.keyBackupSetupSuccessFromSecureBackupViewControllerDidTapDoneAction(self)
    }
}
