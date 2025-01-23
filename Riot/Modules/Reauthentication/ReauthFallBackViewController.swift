//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit

/// View controller used for User-Interactive Authentication fallback (https://matrix.org/docs/spec/client_server/latest#fallback)
final class ReauthFallBackViewController: AuthFallBackViewController, Themable {
    
    // MARK: - Properties
                    
    // MARK: Public
    
    var didValidate: (() -> Void)?
    var didCancel: (() -> Void)?
    
    // MARK: Private
    
    private var theme: Theme = ThemeService.shared().theme
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.setupNavigationBar()
        self.registerThemeServiceDidChangeThemeNotification()
        self.update(theme: self.theme)
    }
    
    // MARK: - Public
    
    func update(theme: Theme) {
        self.theme = theme
                
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
    
    private func setupNavigationBar() {
        let doneBarButtonItem = MXKBarButtonItem(title: VectorL10n.close, style: .plain) { [weak self] in
            self?.didValidate?()
        }        
        self.navigationItem.leftBarButtonItem = doneBarButtonItem
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate
extension ReauthFallBackViewController: UIAdaptivePresentationControllerDelegate {
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        self.didCancel?()
    }
}
