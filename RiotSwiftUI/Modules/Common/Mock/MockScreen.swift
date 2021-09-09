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

/*
 Used for mocking top level screens and their various state.
 */
@available(iOS 14.0, *)
protocol MockScreen {
    associatedtype ScreenType: View
    static func screen(for state: Self) -> ScreenType
    static var screenStates: [Self] { get }
}


@available(iOS 14.0, *)
extension MockScreen {
    
    /*
     Get a list of the screens for every screen state.
     */
    static var screens: [ScreenType] {
        Self.screenStates.map(screen(for:))
    }
    
    /*
     Render each of the screen states in a group applying
     any optional environment variables.
     */
    static func screenGroup(
        themeId: ThemeIdentifier = .light,
        locale: Locale = Locale.current,
        sizeCategory: ContentSizeCategory = ContentSizeCategory.medium
    ) -> some View {
        Group {
            ForEach(0..<screens.count) { index in
                screens[index]
            }
        }
        .theme(themeId)
        .environment(\.locale, locale)
        .environment(\.sizeCategory, sizeCategory)
    }
}
