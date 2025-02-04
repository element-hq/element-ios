//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct SeparatorLine: View {
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    var height: CGFloat = 1.0
    
    var body: some View {
        Rectangle()
            .fill(theme.colors.quinaryContent)
            .frame(maxWidth: .infinity)
            .frame(height: height)
    }
}
