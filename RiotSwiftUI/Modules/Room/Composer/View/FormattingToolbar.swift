//
// Copyright 2022 New Vector Ltd
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
