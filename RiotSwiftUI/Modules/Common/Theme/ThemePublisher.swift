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
