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
