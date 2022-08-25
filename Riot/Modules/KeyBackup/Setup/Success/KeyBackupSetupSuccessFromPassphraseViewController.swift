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

protocol KeyBackupSetupSuccessFromPassphraseViewControllerDelegate: AnyObject {
    func keyBackupSetupSuccessFromPassphraseViewControllerDidTapDoneAction(_ viewController: KeyBackupSetupSuccessFromPassphraseViewController)
}

final class KeyBackupSetupSuccessFromPassphraseViewController: UIViewController {
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private var keyBackupLogoImageView: UIImageView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var informationLabel: UILabel!
    
    @IBOutlet private var saveRecoveryKeyButtonBackgroundView: UIView!
    @IBOutlet private var saveRecoveryKeyButton: UIButton!
    
    @IBOutlet private var doneButtonBackgroundView: UIView!
    @IBOutlet private var doneButton: UIButton!
    
    // MARK: Private
    
    private var theme: Theme!
    private var recoveryKey: String!
    
    // MARK: Public
    
    weak var delegate: KeyBackupSetupSuccessFromPassphraseViewControllerDelegate?
    
    // MARK: - Setup
    
    class func instantiate(with recoveryKey: String) -> KeyBackupSetupSuccessFromPassphraseViewController {
        let viewController = StoryboardScene.KeyBackupSetupSuccessFromPassphraseViewController.initialScene.instantiate()
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
        informationLabel.text = VectorL10n.keyBackupSetupSuccessFromPassphraseInfo
        
        saveRecoveryKeyButton.setTitle(VectorL10n.keyBackupSetupSuccessFromPassphraseSaveRecoveryKeyAction, for: .normal)
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
        
        saveRecoveryKeyButtonBackgroundView.backgroundColor = theme.backgroundColor
        theme.applyStyle(onButton: saveRecoveryKeyButton)
        
        doneButtonBackgroundView.backgroundColor = theme.backgroundColor
        theme.applyStyle(onButton: doneButton)
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        update(theme: ThemeService.shared().theme)
    }
    
    private func shareRecoveryKey() {
        guard let recoveryKey = recoveryKey else {
            return
        }
        
        // Set up activity view controller
        let activityItems: [Any] = [recoveryKey]
        let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        
        // Configure source view when activity view controller is presented with a popover
        if let popoverPresentationController = activityViewController.popoverPresentationController {
            popoverPresentationController.sourceView = saveRecoveryKeyButton
            popoverPresentationController.sourceRect = saveRecoveryKeyButton.bounds
            popoverPresentationController.permittedArrowDirections = [.down, .up]
        }
        
        present(activityViewController, animated: true)
    }
    
    // MARK: - Actions
    
    @IBAction private func saveRecoveryKeyButtonAction(_ sender: Any) {
        shareRecoveryKey()
    }
    
    @IBAction private func doneButtonAction(_ sender: Any) {
        delegate?.keyBackupSetupSuccessFromPassphraseViewControllerDidTapDoneAction(self)
    }
}
