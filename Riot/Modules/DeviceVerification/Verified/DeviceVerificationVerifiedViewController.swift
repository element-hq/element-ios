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

protocol DeviceVerificationVerifiedViewControllerDelegate: class {
    func deviceVerificationVerifiedViewControllerDidTapSetupAction(_ viewController: DeviceVerificationVerifiedViewController)
    func deviceVerificationVerifiedViewControllerDidCancel(_ viewController: DeviceVerificationVerifiedViewController)
}

final class DeviceVerificationVerifiedViewController: UIViewController {
    
    // MARK: - Properties
    
    // MARK: Outlets

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var description1Label: UILabel!
    @IBOutlet private weak var description2Label: UILabel!

    @IBOutlet private weak var okButtonBackgroundView: UIView!
    @IBOutlet private weak var okButton: UIButton!
    
    // MARK: Private
    
    private var theme: Theme!
    
    // MARK: Public
    
    weak var delegate: DeviceVerificationVerifiedViewControllerDelegate?
    
    // MARK: - Setup
    
    class func instantiate() -> DeviceVerificationVerifiedViewController {
        let viewController = StoryboardScene.DeviceVerificationVerifiedViewController.initialScene.instantiate()
        viewController.theme = ThemeService.shared().theme
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.title = VectorL10n.deviceVerificationTitle
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
        self.titleLabel.text =  VectorL10n.deviceVerificationVerifiedTitle
        self.description1Label.text = VectorL10n.deviceVerificationVerifiedDescription1
        self.description2Label.text = VectorL10n.deviceVerificationVerifiedDescription2

        self.okButton.setTitle(VectorL10n.deviceVerificationVerifiedGotItButton, for: .normal)
    }
    
    private func update(theme: Theme) {
        self.theme = theme
        
        self.view.backgroundColor = theme.headerBackgroundColor
        
        if let navigationBar = self.navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }
        
        self.titleLabel.textColor = theme.textPrimaryColor
        self.description1Label.textColor = theme.textPrimaryColor
        self.description2Label.textColor = theme.textPrimaryColor

        self.okButtonBackgroundView.backgroundColor = theme.backgroundColor
        theme.applyStyle(onButton: self.okButton)
            }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }

    // MARK: - Actions
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
    
    @IBAction private func validateButtonAction(_ sender: Any) {
        self.delegate?.deviceVerificationVerifiedViewControllerDidTapSetupAction(self)
    }
}
