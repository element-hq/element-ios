//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

/// Provides the theme and theme updates to SwiftUI.
///
/// Replaces the old ThemeObserver. Riot app can push updates to this class
/// removing the dependency of this class on the `ThemeService`.
class ThemePublisher: ObservableObject {
    private static var _shared: ThemePublisher?
    static var shared: ThemePublisher {
        if _shared == nil {
            configure(themeId: .light)
        }
        return _shared!
    }
    
    @Published private(set) var theme: ThemeSwiftUI
    
    static func configure(themeId: ThemeIdentifier) {
        _shared = ThemePublisher(themeId: themeId)
    }
    
    init(themeId: ThemeIdentifier) {
        _theme = Published(initialValue: themeId.themeSwiftUI)
    }

    func republish(themeIdPublisher: AnyPublisher<ThemeIdentifier, Never>) {
        themeIdPublisher
            .map(\.themeSwiftUI)
            .assign(to: &$theme)
    }
}
