//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// A single rounded rect chip to be rendered within `Chips` collection
struct Chip: View {
    @Environment(\.isEnabled) var isEnabled
    @Environment(\.theme) var theme: ThemeSwiftUI
    
    let title: String
    let onDelete: () -> Void
    
    var backgroundColor: Color {
        if !isEnabled {
            return theme.colors.quinaryContent
        }
        return theme.colors.accent
    }
    
    var foregroundColor: Color {
        if !isEnabled {
            return theme.colors.tertiaryContent
        }
        return Color.white
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(theme.fonts.body)
                .lineLimit(1)
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .frame(width: 16, height: 16, alignment: .center)
            }
        }
        .padding(.leading, 12)
        .padding(.top, 6)
        .padding(.bottom, 6)
        .padding(.trailing, 8)
        .background(backgroundColor)
        .foregroundColor(foregroundColor)
        .cornerRadius(20)
    }
}

struct Chip_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            Chip(title: "My great chip", onDelete: { })
            Chip(title: "My great chip", onDelete: { })
                .theme(.dark)
        }
    }
}
