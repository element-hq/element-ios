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
    
    @IBOutlet private var keyBackupLogoImageView: UIImageView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var informationLabel: UILabel!
    
    @IBOutlet private var recoveryKeySectionBackgroundView: UIView!
    
    @IBOutlet private var recoveryKeyTitleLabel: UILabel!
    @IBOutlet private var recoveryKeyLabel: UILabel!
    
    @IBOutlet private var separatorView: UIView!
    
    @IBOutlet private var makeACopyButton: UIButton!
    
    @IBOutlet private var madeACopyButtonBackgroundView: UIView!
    @IBOutlet private var madeACopyButton: UIButton!
    
    // MARK: Private
    
    private var theme: Theme!
    private var recoveryKey: String!
    private var hasMadeARecoveryKeyCopy = false
    
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
        informationLabel.text = VectorL10n.keyBackupSetupSuccessFromRecoveryKeyInfo
        
        recoveryKeyTitleLabel.text = VectorL10n.keyBackupSetupSuccessFromRecoveryKeyRecoveryKeyTitle
        recoveryKeyLabel.text = recoveryKey
        
        makeACopyButton.setTitle(VectorL10n.keyBackupSetupSuccessFromRecoveryKeyMakeCopyAction, for: .normal)
        madeACopyButton.setTitle(VectorL10n.keyBackupSetupSuccessFromRecoveryKeyMadeCopyAction, for: .normal)
        
        updateDoneButton()
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
        
        recoveryKeySectionBackgroundView.backgroundColor = theme.backgroundColor
        
        recoveryKeyTitleLabel.textColor = theme.textPrimaryColor
        recoveryKeyLabel.textColor = theme.textPrimaryColor
        
        separatorView.backgroundColor = theme.lineBreakColor
        
        theme.applyStyle(onButton: makeACopyButton)
        
        madeACopyButtonBackgroundView.backgroundColor = theme.backgroundColor
        theme.applyStyle(onButton: madeACopyButton)
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        update(theme: ThemeService.shared().theme)
    }
    
    private func shareRecoveryKey() {
        // Set up activity view controller
        let activityItems: [Any] = [recoveryKey as Any]
        let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        
        activityViewController.completionWithItemsHandler = { _, completed, _, _ in
            
            // Enable made copy button only if user has selected an activity item and has setup recovery key without passphrase
            if completed {
                self.hasMadeARecoveryKeyCopy = true
                self.updateDoneButton()
            }
        }
        
        // Configure source view when activity view controller is presented with a popover
        if let popoverPresentationController = activityViewController.popoverPresentationController {
            popoverPresentationController.sourceView = makeACopyButton
            popoverPresentationController.sourceRect = makeACopyButton.bounds
            popoverPresentationController.permittedArrowDirections = [.down, .up]
        }
        
        present(activityViewController, animated: true)
    }
    
    private func updateDoneButton() {
        madeACopyButton.isEnabled = hasMadeARecoveryKeyCopy
    }
    
    // MARK: - Actions
    
    @IBAction private func saveRecoveryKeyButtonAction(_ sender: Any) {
        shareRecoveryKey()
    }
    
    @IBAction private func doneButtonAction(_ sender: Any) {
        delegate?.keyBackupSetupSuccessFromRecoveryKeyViewControllerDidTapDoneAction(self)
    }
}
