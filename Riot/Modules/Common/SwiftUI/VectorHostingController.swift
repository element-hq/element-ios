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
    
    var isNavigationBarHidden: Bool = false
    var hidesBackTitleWhenPushed: Bool = false

    var forceZeroSafeAreaInsets: Bool {
        get {
            self.view.forceZeroSafeAreaInsets
        }
        set {
            self.view.forceZeroSafeAreaInsets = newValue
        }
    }

    private var theme: Theme
    
    // MARK: Public
    
    /// Whether or not to use the iOS 15 style scroll edge appearance when the controller has a navigation bar.
    var enableNavigationBarScrollEdgeAppearance = false
    /// When non-nil, the style will be applied to the status bar.
    var statusBarStyle: UIStatusBarStyle?
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        statusBarStyle ?? super.preferredStatusBarStyle
    }
    
    init<Content>(rootView: Content) where Content: View {
        self.theme = ThemeService.shared().theme
        super.init(rootView: AnyView(rootView.vectorContent()))
        self.view.swizzleSafeAreaMethodsIfNeeded()
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
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
    
    private func update(theme: Theme) {
        if let navigationBar = self.navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar, withModernScrollEdgeAppearance: enableNavigationBarScrollEdgeAppearance)
        }
    }
}

// Hack for forcing zero safe area insets on hosting views. This problem occurs when the hosting view is embedded
// in a table view. See https://stackoverflow.com/questions/61552497 for further info.

private var hasSwizzledSafeAreaMethods = false
private var forceZeroSafeAreaInsetsKey: Void?

private extension UIView {
    
    var forceZeroSafeAreaInsets: Bool {
        get {
            return objc_getAssociatedObject(self, &forceZeroSafeAreaInsetsKey) as? Bool == true
        }
        set {
            objc_setAssociatedObject(self, &forceZeroSafeAreaInsetsKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    @objc private var _safeAreaInsets: UIEdgeInsets {
        return forceZeroSafeAreaInsets ? .zero : self._safeAreaInsets
    }
    
    @objc private var _safeAreaLayoutGuide: UILayoutGuide? {
        return forceZeroSafeAreaInsets ? nil : self._safeAreaLayoutGuide
    }
    
    func swizzleSafeAreaMethodsIfNeeded() {
        guard !hasSwizzledSafeAreaMethods else {
            return
        }
        hasSwizzledSafeAreaMethods = true
        
        guard let getSafeAreaInsets = class_getInstanceMethod(classForCoder.self, #selector(getter: UIView.safeAreaInsets)) else {
            return
        }
        
        guard let _getSafeAreaInsets = class_getInstanceMethod(classForCoder.self, #selector(getter: UIView._safeAreaInsets)) else {
            return
        }
        
        let getSafeAreaInsetsImplementation = method_getImplementation(getSafeAreaInsets)
        let _getSafeAreaInsetsImplementation = method_getImplementation(_getSafeAreaInsets)
        
        class_replaceMethod(
            classForCoder,
            #selector(getter: UIView.safeAreaInsets),
            _getSafeAreaInsetsImplementation,
            method_getTypeEncoding(getSafeAreaInsets))
        
        class_replaceMethod(
            classForCoder,
            #selector(getter: UIView._safeAreaInsets),
            getSafeAreaInsetsImplementation,
            method_getTypeEncoding(_getSafeAreaInsets))

        guard let getSafeAreaLayoutGuide = class_getInstanceMethod(classForCoder.self, #selector(getter: UIView.safeAreaLayoutGuide)) else {
            return
        }
        
        guard let _getSafeAreaLayoutGuide = class_getInstanceMethod(classForCoder.self, #selector(getter: UIView._safeAreaLayoutGuide)) else {
            return
        }
        
        let getSafeAreaLayoutGuideImplementation = method_getImplementation(getSafeAreaLayoutGuide)
        let _getSafeAreaLayoutGuideImplementation = method_getImplementation(_getSafeAreaLayoutGuide)
        
        class_replaceMethod(
            classForCoder,
            #selector(getter: UIView.safeAreaLayoutGuide),
            _getSafeAreaLayoutGuideImplementation,
            method_getTypeEncoding(getSafeAreaLayoutGuide))
        
        class_replaceMethod(
            classForCoder,
            #selector(getter: UIView._safeAreaLayoutGuide),
            getSafeAreaLayoutGuideImplementation,
            method_getTypeEncoding(_getSafeAreaLayoutGuide))
    }

}
