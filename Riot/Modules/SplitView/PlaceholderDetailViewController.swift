// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit

/// Used as a placeholder for UISplitViewController detail view controller
final class PlaceholderDetailViewController: UIViewController, Themable {

    // MARK: - Constants
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var logoImageView: UIImageView!
    
    // MARK: Private
    
    private var theme: Theme!
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.setupViews()
        self.registerThemeServiceDidChangeThemeNotification()
        self.update(theme: self.theme)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.theme.statusBarStyle
    }
    
    // MARK: - Public
    
    // TODO: Extract Storyboard and use SwiftGen
    class func instantiate() -> PlaceholderDetailViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        guard let emptyDetailsViewController = storyboard.instantiateViewController(withIdentifier: "EmptyDetailsViewControllerStoryboardId") as? PlaceholderDetailViewController else {
            fatalError("[PlaceholderDetailViewController] Fail to load view controller from storyboard")
        }
        emptyDetailsViewController.theme = ThemeService.shared().theme
        return emptyDetailsViewController
    }
    
    func update(theme: Theme) {
        self.theme = theme
        
        self.view.backgroundColor = theme.backgroundColor
        self.logoImageView.tintColor = theme.tintColor
        
        if let navigationBar = self.navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }
    }
    
    // MARK: - Private
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
    
    private func setupViews() {
        self.logoImageView.image = Asset.Images.launchScreenLogo.image
    }
}
