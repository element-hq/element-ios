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
 (E.g. `vectorContent` modifier and themeing to the NavigationController container.
 */
@available(iOS 14.0, *)
class VectorHostingController: UIHostingController<AnyView> {
    
    // MARK: Private
    
    private var theme: Theme

    init() {
        self.theme = ThemeService.shared().theme
        super.init(rootView: AnyView(EmptyView()))
    }
    
    init<Content>(rootView: Content) where Content: View {
        self.theme = ThemeService.shared().theme
        super.init(rootView: AnyView(rootView.vectorContent()))
    }
    
    func setRoot<V: View>(view: V) {
        rootView = AnyView(view)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("VectorHostingViewController does not currently support init from nibs")
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.registerThemeServiceDidChangeThemeNotification()
        self.update(theme: self.theme)
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
    
    private func update(theme: Theme) {
        self.view.backgroundColor = theme.headerBackgroundColor
        
        if let navigationBar = self.navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }
    }
}
