//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// A toggle style that uses a button, with a checked/unchecked image like a checkbox.
struct AuthenticationTermsToggleStyle: ToggleStyle {
    @Environment(\.theme) private var theme
    
    func makeBody(configuration: Configuration) -> some View {
        Button { configuration.isOn.toggle() } label: {
            Image(systemName: configuration.isOn ? "checkmark.circle.fill" : "circle")
                .font(.title3.weight(.regular))
                .foregroundColor(theme.colors.accent)
        }
        .buttonStyle(.plain)
    }
}
