//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI
import WysiwygComposer

struct FormattingToolbar: View {
    // MARK: - Properties
    
    // MARK: Private
    
    // MARK: Public
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    /// The list of items to render in the toolbar
    var formatItems: [FormatItem]
    /// The action when an item is selected
    var formatAction: (FormatType) -> Void
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 4) {
                ForEach(formatItems) { item in
                    Button {
                        formatAction(item.type)
                    } label: {
                        Image(item.icon)
                            .renderingMode(.template)
                            .foregroundColor(getForegroundColor(for: item))
                    }
                    .disabled(item.state == .disabled)
                    .frame(width: 44, height: 44)
                    .background(getBackgroundColor(for: item))
                    .cornerRadius(8)
                    .accessibilityIdentifier(item.accessibilityIdentifier)
                    .accessibilityLabel(item.accessibilityLabel)
                }
            }
        }
    }
    
    private func getForegroundColor(for item: FormatItem) -> Color {
        switch item.state {
        case .reversed: return theme.colors.accent
        case .enabled: return theme.colors.tertiaryContent
        case .disabled: return theme.colors.tertiaryContent.opacity(0.3)
        }
    }
    
    private func getBackgroundColor(for item: FormatItem) -> Color {
        switch item.state {
        case .reversed: return theme.colors.accent.opacity(0.1)
        default: return theme.colors.background
        }
    }
}

// MARK: - Previews

struct FormattingToolbar_Previews: PreviewProvider {
    static var previews: some View {
        FormattingToolbar(
            formatItems: FormatType.allCases.map { FormatItem(type: $0, state: .enabled) }
        , formatAction: { _ in })
    }
}
