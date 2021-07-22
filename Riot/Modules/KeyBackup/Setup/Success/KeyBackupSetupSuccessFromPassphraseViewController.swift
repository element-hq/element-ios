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
    
    @IBOutlet private weak var keyBackupLogoImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var informationLabel: UILabel!
    
    @IBOutlet private weak var saveRecoveryKeyButtonBackgroundView: UIView!
    @IBOutlet private weak var saveRecoveryKeyButton: UIButton!
    
    @IBOutlet private weak var doneButtonBackgroundView: UIView!
    @IBOutlet private weak var doneButton: UIButton!
    
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
        self.informationLabel.text = VectorL10n.keyBackupSetupSuccessFromPassphraseInfo
        
        self.saveRecoveryKeyButton.setTitle(VectorL10n.keyBackupSetupSuccessFromPassphraseSaveRecoveryKeyAction, for: .normal)
        self.doneButton.setTitle(VectorL10n.keyBackupSetupSuccessFromPassphraseDoneAction, for: .normal)
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
        
        self.saveRecoveryKeyButtonBackgroundView.backgroundColor = theme.backgroundColor
        theme.applyStyle(onButton: self.saveRecoveryKeyButton)
        
        self.doneButtonBackgroundView.backgroundColor = theme.backgroundColor
        theme.applyStyle(onButton: self.doneButton)
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
    
    private func shareRecoveryKey() {
        guard let recoveryKey = self.recoveryKey else {
            return
        }
        
        // Set up activity view controller
        let activityItems: [Any] = [ recoveryKey ]
        let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        
        // Configure source view when activity view controller is presented with a popover
        if let popoverPresentationController = activityViewController.popoverPresentationController {
            popoverPresentationController.sourceView = self.saveRecoveryKeyButton
            popoverPresentationController.sourceRect = self.saveRecoveryKeyButton.bounds
            popoverPresentationController.permittedArrowDirections = [.down, .up]
        }
        
        self.present(activityViewController, animated: true)
    }
    
    // MARK: - Actions
    
    @IBAction private func saveRecoveryKeyButtonAction(_ sender: Any) {
        self.shareRecoveryKey()
    }
    
    @IBAction private func doneButtonAction(_ sender: Any) {
        self.delegate?.keyBackupSetupSuccessFromPassphraseViewControllerDidTapDoneAction(self)
    }
}
