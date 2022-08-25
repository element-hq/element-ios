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

import DesignKit
import Foundation
import SwiftUI

private struct ThemeKey: EnvironmentKey {
    static let defaultValue = ThemePublisher.shared.theme
}

extension EnvironmentValues {
    var theme: ThemeSwiftUI {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

extension View {
    /// A theme modifier for setting the theme for this view and all its descendants in the hierarchy.
    /// - Parameter theme: A theme to be set as the environment value.
    /// - Returns: The target view with the theme applied.
    func theme(_ theme: ThemeSwiftUI) -> some View {
        environment(\.theme, theme)
    }
}

extension View {
    /// A theme modifier for setting the theme by id for this view and all its descendants in the hierarchy.
    /// - Parameter themeId: ThemeIdentifier of a theme to be set as the environment value.
    /// - Returns: The target view with the theme applied.
    func theme(_ themeId: ThemeIdentifier) -> some View {
        environment(\.theme, themeId.themeSwiftUI)
    }
}
