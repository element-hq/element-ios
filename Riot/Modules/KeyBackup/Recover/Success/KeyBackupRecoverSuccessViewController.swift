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

protocol KeyBackupRecoverSuccessViewControllerDelegate: AnyObject {
    func keyBackupRecoverSuccessViewControllerDidTapDone(_ keyBackupRecoverSuccessViewController: KeyBackupRecoverSuccessViewController)
}

final class KeyBackupRecoverSuccessViewController: UIViewController {
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var shieldImageView: UIImageView!
    
    @IBOutlet private weak var informationLabel: UILabel!
    
    @IBOutlet private weak var doneButtonBackgroundView: UIView!
    @IBOutlet private weak var doneButton: UIButton!
    
    // MARK: Private
    
    private var theme: Theme!
    
    // MARK: Public
    
    weak var delegate: KeyBackupRecoverSuccessViewControllerDelegate?
    
    // MARK: - Setup
    
    class func instantiate() -> KeyBackupRecoverSuccessViewController {
        let viewController = StoryboardScene.KeyBackupRecoverSuccessViewController.initialScene.instantiate()
        viewController.theme = ThemeService.shared().theme
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        self.title = VectorL10n.keyBackupRecoverTitle
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
        let shieldImage = Asset.Images.keyBackupLogo.image.withRenderingMode(.alwaysTemplate)
        self.shieldImageView.image = shieldImage
        
        self.informationLabel.text = VectorL10n.keyBackupRecoverSuccessInfo
        
        self.doneButton.vc_enableMultiLinesTitle()
        self.doneButton.setTitle(VectorL10n.keyBackupRecoverDoneAction, for: .normal)
    }
    
    private func update(theme: Theme) {
        self.theme = theme
        
        self.view.backgroundColor = theme.headerBackgroundColor
        
        if let navigationBar = self.navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }
        
        self.shieldImageView.tintColor = theme.textPrimaryColor
        
        self.informationLabel.textColor = theme.textPrimaryColor
        
        self.doneButtonBackgroundView.backgroundColor = theme.backgroundColor
        theme.applyStyle(onButton: self.doneButton)
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    // MARK: - Actions
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
    
    @IBAction private func doneButtonAction(_ sender: Any) {
        self.delegate?.keyBackupRecoverSuccessViewControllerDidTapDone(self)
    }
}
