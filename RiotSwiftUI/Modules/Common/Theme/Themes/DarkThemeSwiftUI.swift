//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import DesignKit
import Foundation

struct DarkThemeSwiftUI: ThemeSwiftUI {
    var identifier: ThemeIdentifier = .dark
    let isDark = true
    var colors: ColorSwiftUI = DarkColors.swiftUI
    var fonts = FontSwiftUI(values: ElementFonts())
}
