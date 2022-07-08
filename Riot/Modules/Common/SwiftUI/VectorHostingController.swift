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

import Foundation
import SwiftUI

/**
 UIHostingController that applies some app-level specific configuration
 (E.g. `vectorContent` modifier and theming to the NavigationController container.
 */
class VectorHostingController: UIHostingController<AnyView> {
    
    // MARK: Private
    
    private var theme: Theme
    
    // MARK: Public

    /// Wether or not the navigation bar should be hidden. Default `false`
    var isNavigationBarHidden: Bool = false
    /// Wether or not the title of the back item should be hidden. Default `false`
    var hidesBackTitleWhenPushed: Bool = false
    /// Defines the behaviour of the `VectorHostingController` as a bottom sheet. Default `nil`
    var bottomSheetPreferences: VectorHostingBottomSheetPreferences?

    /// Whether or not to use the iOS 15 style scroll edge appearance when the controller has a navigation bar.
    var enableNavigationBarScrollEdgeAppearance = false
    /// When non-nil, the style will be applied to the status bar.
    var statusBarStyle: UIStatusBarStyle?

    private let forceZeroSafeAreaInsets: Bool
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        statusBarStyle ?? super.preferredStatusBarStyle
    }
    /// Initializer
    /// - Parameter rootView: Root view for the controller.
    /// - Parameter forceZeroSafeAreaInsets: Whether to force-set the hosting view's safe area insets to zero. Useful when the view is used as part of a table view.
    init<Content>(rootView: Content,
                  forceZeroSafeAreaInsets: Bool = false) where Content: View {
        self.theme = ThemeService.shared().theme
        self.forceZeroSafeAreaInsets = forceZeroSafeAreaInsets
        super.init(rootView: AnyView(rootView.vectorContent()))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("VectorHostingViewController does not currently support init from nibs")
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .clear
        
        self.registerThemeServiceDidChangeThemeNotification()
        self.update(theme: self.theme)
        
        bottomSheetPreferences?.setup(viewController: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if isNavigationBarHidden {
            self.navigationController?.isNavigationBarHidden = true
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if hidesBackTitleWhenPushed {
            vc_removeBackTitle()
        }
        
        if navigationController?.isNavigationBarHidden ?? false {
            navigationController?.interactivePopGestureRecognizer?.delegate = nil
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    
        // Fixes weird iOS 15 bug where the view no longer grows its enclosing host
        if #available(iOS 15.0, *) {
            self.view.invalidateIntrinsicContentSize()
        }
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()

        guard forceZeroSafeAreaInsets else {
            return
        }

        let counterSafeAreaInsets = UIEdgeInsets(top: -view.safeAreaInsets.top,
                                                 left: -view.safeAreaInsets.left,
                                                 bottom: -view.safeAreaInsets.bottom,
                                                 right: -view.safeAreaInsets.right)
        if additionalSafeAreaInsets != counterSafeAreaInsets, counterSafeAreaInsets != .zero {
            additionalSafeAreaInsets = counterSafeAreaInsets
        }
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
    
    private func update(theme: Theme) {
        // Ensure dynamic colors are shown correctly when the theme is the opposite appearance to the system.
        overrideUserInterfaceStyle = theme.userInterfaceStyle
        
        if let navigationBar = self.navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar, withModernScrollEdgeAppearance: enableNavigationBarScrollEdgeAppearance)
        }
    }
}
