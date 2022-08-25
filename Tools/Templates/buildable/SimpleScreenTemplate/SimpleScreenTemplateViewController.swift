/*
 Copyright 2021 New Vector Ltd
 
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

protocol SimpleScreenTemplateViewControllerDelegate: AnyObject {
    func simpleScreenTemplateViewControllerDidTapSetupAction(_ viewController: SimpleScreenTemplateViewController)
    func simpleScreenTemplateViewControllerDidCancel(_ viewController: SimpleScreenTemplateViewController)
}

final class SimpleScreenTemplateViewController: UIViewController {
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private var logoImageView: UIImageView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var informationLabel: UILabel!
    
    @IBOutlet private var okButtonBackgroundView: UIView!
    @IBOutlet private var okButton: UIButton!
    
    // MARK: Private
    
    private var theme: Theme!
    
    // MARK: Public
    
    weak var delegate: SimpleScreenTemplateViewControllerDelegate?
    
    // MARK: - Setup
    
    class func instantiate() -> SimpleScreenTemplateViewController {
        let viewController = StoryboardScene.SimpleScreenTemplateViewController.initialScene.instantiate()
        viewController.theme = ThemeService.shared().theme
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        title = "Template"
        vc_removeBackTitle()
        
        setupViews()
        registerThemeServiceDidChangeThemeNotification()
        update(theme: theme)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        theme.statusBarStyle
    }
    
    // MARK: - Private
    
    private func setupViews() {
        let cancelBarButtonItem = MXKBarButtonItem(title: VectorL10n.cancel, style: .plain) { [weak self] in
            self?.cancelButtonAction()
        }
        navigationItem.rightBarButtonItem = cancelBarButtonItem
        
//        let logoImage = Asset.Images.*
//        self.logoImageView.image = keybackupLogoImage

//        self.titleLabel.text =  VectorL10n.xxxxTitle
//        self.informationLabel.text = VectorL10n.xxxxDescription
//
//        self.okButton.setTitle(VectorL10n.xxxxAction, for: .normal)
    }
    
    private func update(theme: Theme) {
        self.theme = theme
        
        view.backgroundColor = theme.headerBackgroundColor
        
        if let navigationBar = navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }
        
        logoImageView.tintColor = theme.textPrimaryColor
        
        titleLabel.textColor = theme.textPrimaryColor
        informationLabel.textColor = theme.textPrimaryColor
        
        okButtonBackgroundView.backgroundColor = theme.backgroundColor
        theme.applyStyle(onButton: okButton)
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }

    // MARK: - Actions
    
    @objc private func themeDidChange() {
        update(theme: ThemeService.shared().theme)
    }
    
    @IBAction private func validateButtonAction(_ sender: Any) {
        delegate?.simpleScreenTemplateViewControllerDidTapSetupAction(self)
    }

    private func cancelButtonAction() {
        delegate?.simpleScreenTemplateViewControllerDidCancel(self)
    }
}
