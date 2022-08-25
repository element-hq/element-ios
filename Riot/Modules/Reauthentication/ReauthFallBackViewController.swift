//
// Copyright 2021 New Vector Ltd
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
        setupNavigationBar()
        registerThemeServiceDidChangeThemeNotification()
        update(theme: theme)
    }
    
    // MARK: - Public
    
    func update(theme: Theme) {
        self.theme = theme
                
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
    
    private func setupNavigationBar() {
        let doneBarButtonItem = MXKBarButtonItem(title: VectorL10n.close, style: .plain) { [weak self] in
            self?.didValidate?()
        }
        navigationItem.leftBarButtonItem = doneBarButtonItem
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension ReauthFallBackViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        didCancel?()
    }
}
