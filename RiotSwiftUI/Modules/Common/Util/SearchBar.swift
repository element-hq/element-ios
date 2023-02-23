//
// Copyright 2021 New Vector Ltd
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
