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

/// A Modifier to be called from the top-most SwiftUI view before being added to a HostViewController.
///
/// Provides any app level configuration the SwiftUI hierarchy might need (E.g. to monitor theme changes).
struct VectorContentModifier: ViewModifier {
    
    @ObservedObject private var themePublisher = ThemePublisher.shared
    @Environment(\.layoutDirection) private var defaultLayoutDirection
    
    /// The layout direction to use, taking into account the build settings. SwiftUI generally
    /// handles RTL well enough, but we match the behaviour used in UIKit to avoid mixed layouts.
    var layoutDirection: LayoutDirection {
        BuildSettings.disableRightToLeftLayout ? .leftToRight : defaultLayoutDirection
    }
    
    func body(content: Content) -> some View {
        content
            .theme(themePublisher.theme)
            .environment(\.layoutDirection, layoutDirection)
    }
}

extension View {
    func vectorContent() -> some View {
        self.modifier(VectorContentModifier())
    }
}
