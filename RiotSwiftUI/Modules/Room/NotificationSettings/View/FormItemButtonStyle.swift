//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import SwiftUI

struct FormItemButtonStyle: ButtonStyle {
    @Environment(\.theme) var theme: ThemeSwiftUI
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? theme.colors.system : theme.colors.background)
            .foregroundColor(theme.colors.primaryContent)
            .font(theme.fonts.body)
    }
}
