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

import SwiftUI

/// Used for mocking top level screens and their various states.
@available(iOS 14.0, *)
protocol MockScreenState {
    static var screenStates: [MockScreenState] { get }
    var screenType: Any.Type { get }
    var screenView: AnyView { get }
    var stateTitle: String { get }
}

@available(iOS 14.0, *)
extension MockScreenState {
    
    /// Get a list of the screens for every screen state.
    static var screensViews: [AnyView] {
        screenStates.map(\.screenView)
    }
    
    /// A unique key to identify each screen state.
    static var screenStateKeys: [String] {
        return Array(0..<screenStates.count).map(String.init)
    }
    
    /// Render each of the screen states in a group applying
    /// any optional environment variables.
    /// - Parameters:
    ///   - themeId: id of theme to render the screens with
    ///   - locale: Locale to render the screens with
    ///   - sizeCategory: type sizeCategory to render the screens with
    /// - Returns: The group of screens
    static func screenGroup(
        themeId: ThemeIdentifier = .light,
        locale: Locale = Locale.current,
        sizeCategory: ContentSizeCategory = ContentSizeCategory.medium,
        addNavigation: Bool = false
    ) -> some View {
        Group {
            ForEach(0..<screensViews.count) { index in
                if addNavigation {
                    NavigationView{
                        screensViews[index]
                    }
                } else {
                    screensViews[index]
                }
            }
        }
        .theme(themeId)
        .environment(\.locale, locale)
        .environment(\.sizeCategory, sizeCategory)
    }
    
    /// A title to represent the screen and it's screen state
    var screenTitle: String {
        "\(String(describing: screenType.self)): \(stateTitle)"
    }
    
    /// A title to represent this screen state
    var stateTitle: String {
        String(describing: self)
    }
}

@available(iOS 14.0, *)
extension MockScreenState where Self: CaseIterable {
    static var screenStates: [MockScreenState] {
        return Array(self.allCases)
    }
}
