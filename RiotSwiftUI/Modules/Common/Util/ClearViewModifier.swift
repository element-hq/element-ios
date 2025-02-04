//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

extension ThemableTextEditor {
    func showClearButton(text: Binding<String>, alignment: VerticalAlignment = .top) -> some View {
        modifier(ClearViewModifier(alignment: alignment, text: text))
    }
}

/// `ClearViewModifier` aims to add a clear button (e.g. `x` button) on the right side of any text editing view
struct ClearViewModifier: ViewModifier {
    // MARK: - Properties
    
    let alignment: VerticalAlignment
    
    // MARK: - Bindings
    
    @Binding var text: String
    
    // MARK: - Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI

    // MARK: - Public
    
    public func body(content: Content) -> some View {
        HStack(alignment: alignment) {
            content
            if !text.isEmpty {
                Button(action: {
                    self.text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .renderingMode(.template)
                        .foregroundColor(theme.colors.quarterlyContent)
                }
                .padding(.top, alignment == .top ? 8 : 0)
                .padding(.bottom, alignment == .bottom ? 8 : 0)
                .padding(.trailing, 12)
            }
        }
    }
}
