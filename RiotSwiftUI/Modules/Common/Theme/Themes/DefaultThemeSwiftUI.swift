//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import DesignKit
import Foundation

struct DefaultThemeSwiftUI: ThemeSwiftUI {
    var identifier: ThemeIdentifier = .light
    let isDark = false
    var colors: ColorSwiftUI = LightColors.swiftUI
    var fonts = FontSwiftUI(values: ElementFonts())
}
