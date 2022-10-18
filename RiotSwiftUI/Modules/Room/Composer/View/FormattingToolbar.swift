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
        HStack(spacing: 4) {
            ForEach(formatItems) { item in
                Button {
                    formatAction(item.type)
                } label: {
                    Image(item.icon)
                        .renderingMode(.template)
                        .foregroundColor(item.active ? theme.colors.accent : theme.colors.tertiaryContent)
                }
                .disabled(item.disabled)
                .frame(width: 44, height: 44)
                .background(item.active ? theme.colors.accent.opacity(0.1) : theme.colors.background)
                .cornerRadius(8)
                .accessibilityIdentifier(item.accessibilityIdentifier)
                .accessibilityLabel(item.accessibilityLabel)
            }
        }
    }
}

// MARK: - Previews

struct FormattingToolbar_Previews: PreviewProvider {
    static var previews: some View {
        FormattingToolbar(formatItems: [
            FormatItem(type: .bold, active: true, disabled: false),
            FormatItem(type: .italic, active: false, disabled: false),
            FormatItem(type: .strikethrough, active: true, disabled: false),
            FormatItem(type: .underline, active: false, disabled: true)
        ], formatAction: { _ in })
    }
}
