//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct OnboardingButtonStyle: ButtonStyle {
    @Environment(\.theme) private var theme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(configuration.isPressed ? theme.colors.accent : theme.colors.quinaryContent, lineWidth: configuration.isPressed ? 2 : 1.5)
            )
            .contentShape(RoundedRectangle(cornerRadius: 8))
    }
}
