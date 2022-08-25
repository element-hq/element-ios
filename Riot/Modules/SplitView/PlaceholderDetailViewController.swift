//
// Copyright 2020 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import UIKit

/// Used as a placeholder for UISplitViewController detail view controller
final class PlaceholderDetailViewController: UIViewController, Themable {
    // MARK: - Constants
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private var logoImageView: UIImageView!
    
    // MARK: Private
    
    private var theme: Theme!
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupViews()
        registerThemeServiceDidChangeThemeNotification()
        update(theme: theme)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        theme.statusBarStyle
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
        
        view.backgroundColor = theme.backgroundColor
        logoImageView.tintColor = theme.tintColor
        
        if let navigationBar = navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }
    }
    
    // MARK: - Private
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        update(theme: ThemeService.shared().theme)
    }
    
    private func setupViews() {
        logoImageView.image = Asset.Images.launchScreenLogo.image
    }
}
