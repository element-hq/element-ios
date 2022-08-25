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
    
    @IBOutlet private var shieldImageView: UIImageView!
    
    @IBOutlet private var informationLabel: UILabel!
    
    @IBOutlet private var doneButtonBackgroundView: UIView!
    @IBOutlet private var doneButton: UIButton!
    
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
        
        title = VectorL10n.keyBackupRecoverTitle
        vc_removeBackTitle()
        
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
        let shieldImage = Asset.Images.keyBackupLogo.image.withRenderingMode(.alwaysTemplate)
        shieldImageView.image = shieldImage
        
        informationLabel.text = VectorL10n.keyBackupRecoverSuccessInfo
        
        doneButton.vc_enableMultiLinesTitle()
        doneButton.setTitle(VectorL10n.keyBackupRecoverDoneAction, for: .normal)
    }
    
    private func update(theme: Theme) {
        self.theme = theme
        
        view.backgroundColor = theme.headerBackgroundColor
        
        if let navigationBar = navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }
        
        shieldImageView.tintColor = theme.textPrimaryColor
        
        informationLabel.textColor = theme.textPrimaryColor
        
        doneButtonBackgroundView.backgroundColor = theme.backgroundColor
        theme.applyStyle(onButton: doneButton)
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    // MARK: - Actions
    
    @objc private func themeDidChange() {
        update(theme: ThemeService.shared().theme)
    }
    
    @IBAction private func doneButtonAction(_ sender: Any) {
        delegate?.keyBackupRecoverSuccessViewControllerDidTapDone(self)
    }
}
