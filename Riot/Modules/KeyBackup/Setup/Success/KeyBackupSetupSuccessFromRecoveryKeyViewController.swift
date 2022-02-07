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

protocol KeyBackupSetupSuccessFromRecoveryKeyViewControllerDelegate: AnyObject {
    func keyBackupSetupSuccessFromRecoveryKeyViewControllerDidTapDoneAction(_ viewController: KeyBackupSetupSuccessFromRecoveryKeyViewController)
}

final class KeyBackupSetupSuccessFromRecoveryKeyViewController: UIViewController {
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var keyBackupLogoImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var informationLabel: UILabel!
    
    @IBOutlet private weak var recoveryKeySectionBackgroundView: UIView!
    
    @IBOutlet private weak var recoveryKeyTitleLabel: UILabel!
    @IBOutlet private weak var recoveryKeyLabel: UILabel!
    
    @IBOutlet private weak var separatorView: UIView!
    
    @IBOutlet private weak var makeACopyButton: UIButton!
    
    @IBOutlet private weak var madeACopyButtonBackgroundView: UIView!
    @IBOutlet private weak var madeACopyButton: UIButton!
    
    // MARK: Private
    
    private var theme: Theme!
    private var recoveryKey: String!
    private var hasMadeARecoveryKeyCopy: Bool = false
    
    // MARK: Public
    
    weak var delegate: KeyBackupSetupSuccessFromRecoveryKeyViewControllerDelegate?
    
    // MARK: - Setup
    
    class func instantiate(with recoveryKey: String) -> KeyBackupSetupSuccessFromRecoveryKeyViewController {
        let viewController = StoryboardScene.KeyBackupSetupSuccessFromRecoveryKeyViewController.initialScene.instantiate()
        viewController.theme = ThemeService.shared().theme
        viewController.recoveryKey = recoveryKey
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        self.title = VectorL10n.keyBackupSetupTitle
        
        self.setupViews()
        self.registerThemeServiceDidChangeThemeNotification()
        self.update(theme: self.theme)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide back button
        self.navigationItem.setHidesBackButton(true, animated: animated)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.theme.statusBarStyle
    }
    
    // MARK: - Private
    
    private func setupViews() {
        
        let keybackupLogoImage = Asset.Images.keyBackupLogo.image.withRenderingMode(.alwaysTemplate)
        self.keyBackupLogoImageView.image = keybackupLogoImage
        
        self.titleLabel.text = VectorL10n.keyBackupSetupSuccessTitle
        self.informationLabel.text = VectorL10n.keyBackupSetupSuccessFromRecoveryKeyInfo
        
        self.recoveryKeyTitleLabel.text = VectorL10n.keyBackupSetupSuccessFromRecoveryKeyRecoveryKeyTitle
        self.recoveryKeyLabel.text = self.recoveryKey
        
        self.makeACopyButton.setTitle(VectorL10n.keyBackupSetupSuccessFromRecoveryKeyMakeCopyAction, for: .normal)
        self.madeACopyButton.setTitle(VectorL10n.keyBackupSetupSuccessFromRecoveryKeyMadeCopyAction, for: .normal)
        
        self.updateDoneButton()
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
        
        self.recoveryKeySectionBackgroundView.backgroundColor = theme.backgroundColor
        
        self.recoveryKeyTitleLabel.textColor = theme.textPrimaryColor
        self.recoveryKeyLabel.textColor = theme.textPrimaryColor
        
        self.separatorView.backgroundColor = theme.lineBreakColor
        
        theme.applyStyle(onButton: self.makeACopyButton)
        
        self.madeACopyButtonBackgroundView.backgroundColor = theme.backgroundColor
        theme.applyStyle(onButton: self.madeACopyButton)
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
    
    private func shareRecoveryKey() {
        
        // Set up activity view controller
        let activityItems: [Any] = [ self.recoveryKey as Any ]
        let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        
        activityViewController.completionWithItemsHandler = { (activityType, completed, returnedItems, error) in
            
            // Enable made copy button only if user has selected an activity item and has setup recovery key without passphrase
            if completed {
                self.hasMadeARecoveryKeyCopy = true
                self.updateDoneButton()
            }
        }
        
        // Configure source view when activity view controller is presented with a popover
        if let popoverPresentationController = activityViewController.popoverPresentationController {
            popoverPresentationController.sourceView = self.makeACopyButton
            popoverPresentationController.sourceRect = self.makeACopyButton.bounds
            popoverPresentationController.permittedArrowDirections = [.down, .up]
        }
        
        self.present(activityViewController, animated: true)
    }
    
    private func updateDoneButton() {
        self.madeACopyButton.isEnabled = self.hasMadeARecoveryKeyCopy
    }
    
    // MARK: - Actions
    
    @IBAction private func saveRecoveryKeyButtonAction(_ sender: Any) {
        self.shareRecoveryKey()
    }
    
    @IBAction private func doneButtonAction(_ sender: Any) {
        self.delegate?.keyBackupSetupSuccessFromRecoveryKeyViewControllerDidTapDoneAction(self)
    }
}
