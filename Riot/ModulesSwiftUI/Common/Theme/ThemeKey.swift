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

private struct ThemeKey: EnvironmentKey {
    static let defaultValue = ThemeService.shared().theme
}

@available(iOS 14.0, *)
extension EnvironmentValues {
  var theme: Theme {
    get { self[ThemeKey.self] }
    set { self[ThemeKey.self] = newValue }
  }
}

/**
 A theme modifier for setting the theme for this view and all its descendants in the hierarchy.
 - Parameters:
  - theme: a Theme to be set as the environment value.
 */
@available(iOS 14.0, *)
extension View {
  func theme(_ theme: Theme) -> some View {
    environment(\.theme, theme)
  }
}

/**
 A theme modifier for setting the theme by id for this view and all its descendants in the hierarchy.
 - Parameters:
  - themeId: ThemeIdentifier of a theme to be set as the environment value.
 */
@available(iOS 14.0, *)
extension View {
  func theme(_ themeId: ThemeIdentifier) -> some View {
    let theme = ThemeService.shared().theme(withThemeId: themeId.rawValue)
    return environment(\.theme, theme)
  }
}
