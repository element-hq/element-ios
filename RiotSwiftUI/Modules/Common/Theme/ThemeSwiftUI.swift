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
import DesignKit
import DesignTokens

protocol ThemeSwiftUI: ThemeSwiftUIType {
    var identifier: ThemeIdentifier { get }
    var isDark: Bool { get }
}

/// Theme v2 for SwiftUI.
@available(iOS 14.0, *)
public protocol ThemeSwiftUIType {
    
    /// Colors object
    var colors: ElementColors { get }
    
    /// Fonts object
    var fonts: ElementFonts { get }
    
    /// may contain more design components in future, like icons, audio files etc.
}

#warning("Temporary missing colors")
public extension ElementColors {
    var quarterlyContent: Color { quaternaryContent }
    var navigation: Color { system }
    var tile: Color { system }
    var namesAndAvatars: [Color] {
        [
            globalAzure,
            globalGrape,
            globalVerde,
            globalPolly,
            globalMelon,
            globalAqua,
            globalPrune,
            globalKiwi
        ]
    }
}
