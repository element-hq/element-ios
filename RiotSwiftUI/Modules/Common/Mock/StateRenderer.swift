//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import SwiftUI

class StateRenderer {
    var states: [ScreenStateInfo]
    init(states: [ScreenStateInfo]) {
        self.states = states
    }
    
    /// Render each of the screen states in a group applying
    /// any optional environment variables.
    /// - Parameters:
    ///   - themeId: id of theme to render the screens with.
    ///   - locale: Locale to render the screens with.
    ///   - sizeCategory: type sizeCategory to render the screens with.
    ///   - addNavigation: Wether to wrap the screens in a navigation view.
    /// - Returns: The group of screens
    func screenGroup(
        addNavigation: Bool = false
    ) -> some View {
        Group {
            ForEach(0..<states.count, id: \.self) { i in
                let state = self.states[i]
                Self.wrapWithNavigation(addNavigation, view: state.view)
                    .previewDisplayName(state.screenTitle)
            }
        }
    }
    
    @ViewBuilder
    static func wrapWithNavigation<V: View>(_ wrap: Bool, view: V) -> some View {
        if wrap {
            NavigationView {
                view
                    .navigationBarTitleDisplayMode(.inline)
            }
        } else {
            view
        }
    }
}
