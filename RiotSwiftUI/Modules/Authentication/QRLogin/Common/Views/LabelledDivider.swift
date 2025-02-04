//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import SwiftUI

struct LabelledDivider: View {
    @Environment(\.theme) private var theme

    let label: String
    let font: Font? // theme.fonts.subheadline by default
    let labelColor: Color? // theme.colors.primaryContent by default
    let lineColor: Color? // theme.colors.quinaryContent by default

    init(label: String,
         font: Font? = nil,
         labelColor: Color? = nil,
         lineColor: Color? = nil) {
        self.label = label
        self.font = font
        self.labelColor = labelColor
        self.lineColor = lineColor
    }

    var body: some View {
        HStack {
            line
            Text(label)
                .foregroundColor(labelColor ?? theme.colors.primaryContent)
                .font(font ?? theme.fonts.subheadline)
                .fixedSize()
            line
        }
    }

    var line: some View {
        VStack { Divider().background(lineColor ?? theme.colors.quinaryContent) }
    }
}

// MARK: - Previews

struct LabelledDivider_Previews: PreviewProvider {
    static var previews: some View {
        LabelledDivider(label: "Label")
            .theme(.light).preferredColorScheme(.light)
        LabelledDivider(label: "Label")
            .theme(.dark).preferredColorScheme(.dark)
    }
}
