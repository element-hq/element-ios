// File created from simpleScreenTemplate
// $ createSimpleScreen.sh DeviceVerification/Verified DeviceVerificationVerified
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
        
        self.title = self.verificationKind.verificationTitle
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
