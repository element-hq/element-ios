//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct SearchBar: View {
    // MARK: - Properties
    
    var placeholder: String
    @Binding var text: String

    // MARK: - Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    @State private var isEditing = false
    var onTextChanged: ((String) -> Void)?

    // MARK: - Public
    
    var body: some View {
        HStack {
            TextField(placeholder, text: $text) { isEditing in
                self.isEditing = isEditing
            }
            .padding(8)
            .padding(.horizontal, 25)
            .background(theme.colors.navigation)
            .cornerRadius(8)
            .padding(.leading)
            .padding(.trailing, isEditing ? 8 : 16)
            .overlay(
                HStack {
                    Image(systemName: "magnifyingglass")
                        .renderingMode(.template)
                        .foregroundColor(theme.colors.quarterlyContent)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
             
                    if isEditing, !text.isEmpty {
                        Button(action: {
                            self.text = ""
                        }) {
                            Image(systemName: "multiply.circle.fill")
                                .renderingMode(.template)
                                .foregroundColor(theme.colors.quarterlyContent)
                        }
                    }
                }
                .padding(.horizontal, 22)
            )
            if isEditing {
                Button(action: {
                    self.isEditing = false
                    self.text = ""
                    self.hideKeyboard()
                }) {
                    Text(VectorL10n.cancel)
                        .font(theme.fonts.body)
                }
                .foregroundColor(theme.colors.accent)
                .padding(.trailing)
                .transition(.move(edge: .trailing))
            }
        }
        .animation(.default)
    }
}
