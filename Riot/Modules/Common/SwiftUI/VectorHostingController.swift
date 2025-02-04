// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import SwiftUI
import Combine

/**
 UIHostingController that applies some app-level specific configuration
 (E.g. `vectorContent` modifier and theming to the NavigationController container.
 */
class VectorHostingController: UIHostingController<AnyView> {
    
    // MARK: Private

    private var theme: Theme
    private var heightSubject = CurrentValueSubject<CGFloat, Never>(0)
    
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
    /// Whether or not to publish when the height of the view changes.
    var publishHeightChanges: Bool = false
    /// The publisher to subscribe to if `publishHeightChanges` is enabled.
    var heightPublisher: AnyPublisher<CGFloat, Never> {
        return heightSubject.eraseToAnyPublisher()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        statusBarStyle ?? super.preferredStatusBarStyle
    }
    /// Initializer
    /// - Parameter rootView: Root view for the controller.
    init<Content>(rootView: Content) where Content: View {
        self.theme = ThemeService.shared().theme
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if hidesBackTitleWhenPushed {
            vc_removeBackTitle()
        }
        
        if navigationController?.isNavigationBarHidden ?? false {
            navigationController?.interactivePopGestureRecognizer?.delegate = nil
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        guard
            let navigationController = navigationController,
            navigationController.topViewController == self,
            navigationController.isNavigationBarHidden != isNavigationBarHidden
        else { return }
        
        navigationController.isNavigationBarHidden = isNavigationBarHidden
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    
        // Fixes weird iOS 15 bug where the view no longer grows its enclosing host
        if #available(iOS 15.0, *) {
            self.view.invalidateIntrinsicContentSize()
        }
        if publishHeightChanges {
            let height = sizeThatFits(in: CGSize(width: self.view.frame.width, height: UIView.layoutFittingExpandedSize.height)).height
            heightSubject.send(height)
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
