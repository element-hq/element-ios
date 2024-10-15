/*
Copyright 2021-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import UIKit

protocol KeyBackupSetupSuccessFromSecureBackupViewControllerDelegate: AnyObject {
    func keyBackupSetupSuccessFromSecureBackupViewControllerDidTapDoneAction(_ viewController: KeyBackupSetupSuccessFromSecureBackupViewController)
}

final class KeyBackupSetupSuccessFromSecureBackupViewController: UIViewController {    
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var keyBackupLogoImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var informationLabel: UILabel!
    
    @IBOutlet private weak var doneButtonBackgroundView: UIView!
    @IBOutlet private weak var doneButton: UIButton!
    
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
        self.informationLabel.text = VectorL10n.keyBackupSetupSuccessFromSecureBackupInfo
        
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
        
        self.doneButtonBackgroundView.backgroundColor = theme.backgroundColor
        theme.applyStyle(onButton: self.doneButton)
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
    
    // MARK: - Actions
    
    @IBAction private func doneButtonAction(_ sender: Any) {
        self.delegate?.keyBackupSetupSuccessFromSecureBackupViewControllerDidTapDoneAction(self)
    }
}
