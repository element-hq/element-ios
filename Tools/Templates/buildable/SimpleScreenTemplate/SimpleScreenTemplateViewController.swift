/*
Copyright 2021-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import UIKit

protocol SimpleScreenTemplateViewControllerDelegate: AnyObject {
    func simpleScreenTemplateViewControllerDidTapSetupAction(_ viewController: SimpleScreenTemplateViewController)
    func simpleScreenTemplateViewControllerDidCancel(_ viewController: SimpleScreenTemplateViewController)
}

final class SimpleScreenTemplateViewController: UIViewController {
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var logoImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var informationLabel: UILabel!
    
    @IBOutlet private weak var okButtonBackgroundView: UIView!
    @IBOutlet private weak var okButton: UIButton!
    
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
        
        self.title = "Template"
        self.vc_removeBackTitle()
        
        self.setupViews()
        self.registerThemeServiceDidChangeThemeNotification()
        self.update(theme: self.theme)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.theme.statusBarStyle
    }
    
    // MARK: - Private
    
    private func setupViews() {
        let cancelBarButtonItem = MXKBarButtonItem(title: VectorL10n.cancel, style: .plain) { [weak self] in
            self?.cancelButtonAction()
        }
        self.navigationItem.rightBarButtonItem = cancelBarButtonItem
        
//        let logoImage = Asset.Images.*
//        self.logoImageView.image = keybackupLogoImage

//        self.titleLabel.text =  VectorL10n.xxxxTitle
//        self.informationLabel.text = VectorL10n.xxxxDescription
//
//        self.okButton.setTitle(VectorL10n.xxxxAction, for: .normal)
    }
    
    private func update(theme: Theme) {
        self.theme = theme
        
        self.view.backgroundColor = theme.headerBackgroundColor
        
        if let navigationBar = self.navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }
        
        self.logoImageView.tintColor = theme.textPrimaryColor
        
        self.titleLabel.textColor = theme.textPrimaryColor
        self.informationLabel.textColor = theme.textPrimaryColor
        
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
        self.delegate?.simpleScreenTemplateViewControllerDidTapSetupAction(self)
    }

    private func cancelButtonAction() {
        self.delegate?.simpleScreenTemplateViewControllerDidCancel(self)
    }
}
