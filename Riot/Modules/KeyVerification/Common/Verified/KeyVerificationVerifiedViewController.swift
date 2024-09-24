// File created from simpleScreenTemplate
// $ createSimpleScreen.sh DeviceVerification/Verified DeviceVerificationVerified
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import UIKit

protocol KeyVerificationVerifiedViewControllerDelegate: AnyObject {
    func keyVerificationVerifiedViewControllerDidTapSetupAction(_ viewController: KeyVerificationVerifiedViewController)
    func keyVerificationVerifiedViewControllerDidCancel(_ viewController: KeyVerificationVerifiedViewController)
}

final class KeyVerificationVerifiedViewController: UIViewController {
    
    // MARK: - Properties
    
    // MARK: Outlets

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var informationLabel: UILabel!
    @IBOutlet private weak var doneButton: RoundedButton!
    
    // MARK: Private
    
    private var theme: Theme!
    private var verificationKind: KeyVerificationKind = .user
    
    // MARK: Public
    
    weak var delegate: KeyVerificationVerifiedViewControllerDelegate?
    
    // MARK: - Setup
    
    class func instantiate(with verificationKind: KeyVerificationKind) -> KeyVerificationVerifiedViewController {
        let viewController = StoryboardScene.KeyVerificationVerifiedViewController.initialScene.instantiate()
        viewController.theme = ThemeService.shared().theme
        viewController.verificationKind = verificationKind
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
        let bodyTitle: String
        let informationText: String
        
        switch self.verificationKind {
        case .otherSession:
            bodyTitle = VectorL10n.deviceVerificationVerifiedTitle
            informationText = VectorL10n.keyVerificationVerifiedOtherSessionInformation
        case .newSession:
            bodyTitle = VectorL10n.keyVerificationVerifiedNewSessionTitle
            informationText = VectorL10n.keyVerificationVerifiedNewSessionInformation
        case .thisSession:
            bodyTitle = VectorL10n.deviceVerificationVerifiedTitle
            informationText = VectorL10n.keyVerificationVerifiedThisSessionInformation
        case .user:
            bodyTitle = VectorL10n.deviceVerificationVerifiedTitle
            informationText = VectorL10n.keyVerificationVerifiedUserInformation
        }
        
        self.titleLabel.text =  bodyTitle
        self.informationLabel.text = informationText

        self.doneButton.setTitle(VectorL10n.deviceVerificationVerifiedGotItButton, for: .normal)
    }
    
    private func update(theme: Theme) {
        self.theme = theme
        
        self.view.backgroundColor = theme.headerBackgroundColor
        
        if let navigationBar = self.navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }
        
        self.titleLabel.textColor = theme.textPrimaryColor
        self.informationLabel.textColor = theme.textPrimaryColor
        self.doneButton.update(theme: theme)
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }

    // MARK: - Actions
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
    
    @IBAction private func doneButtonAction(_ sender: Any) {
        self.delegate?.keyVerificationVerifiedViewControllerDidTapSetupAction(self)
    }
}
