//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct RoundedBorderTextEditor: View {
    // MARK: - Properties
    
    var title: String?
    let placeHolder: String
    @Binding var text: String
    var textMaxHeight: CGFloat?
    var error: String?
    
    var onTextChanged: ((String) -> Void)?
    var onEditingChanged: ((Bool) -> Void)?

    @State private var editing = false
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    @Environment(\.isEnabled) private var isEnabled
    
    // MARK: Public
    
    var body: some View {
        VStack(alignment: .leading, spacing: -1) {
            if let title = self.title {
                Text(title)
                    .foregroundColor(theme.colors.primaryContent)
                    .font(theme.fonts.subheadline)
                    .multilineTextAlignment(.leading)
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
            }
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeHolder)
                        .padding(EdgeInsets(top: 10, leading: 10, bottom: 0, trailing: 0))
                        .font(theme.fonts.callout)
                        .foregroundColor(theme.colors.tertiaryContent)
                        .allowsHitTesting(false)
                }
                if isEnabled {
                    ThemableTextEditor(text: $text, onEditingChanged: { edit in
                        self.editing = edit
                        onEditingChanged?(edit)
                    })
                    .showClearButton(text: $text)
                    // Found no good solution here. Hidding next button for the moment
                    //                .modifier(NextViewModifier(alignment: .bottomTrailing, isEditing: $editing))
                    .padding(EdgeInsets(top: 2, leading: 6, bottom: 0, trailing: 0))
                    .onChange(of: text, perform: { newText in
                        onTextChanged?(newText)
                    })
                } else {
                    ThemableTextEditor(text: $text, onEditingChanged: { edit in
                        self.editing = edit
                        onEditingChanged?(edit)
                    })
                    .padding(EdgeInsets(top: 2, leading: 6, bottom: 0, trailing: 6))
                    .onChange(of: text, perform: { newText in
                        onTextChanged?(newText)
                    })
                    .opacity(0.5)
                    .allowsHitTesting(false)
                }
            }
            .background(RoundedRectangle(cornerRadius: 8).fill(theme.colors.background))
            .overlay(RoundedRectangle(cornerRadius: 8)
                .stroke(editing ? theme.colors.accent : (error == nil ? theme.colors.quinaryContent : theme.colors.alert), lineWidth: editing || error != nil ? 2 : 1))
            .frame(height: textMaxHeight)
            if let error = self.error {
                Text(error)
                    .foregroundColor(theme.colors.alert)
                    .font(theme.fonts.footnote)
                    .multilineTextAlignment(.leading)
                    .padding(EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0))
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.2), value: error)
    }
}

// MARK: - Previews

struct ThemableTextEditor_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            sampleView.theme(.light).preferredColorScheme(.light)
            sampleView.theme(.dark).preferredColorScheme(.dark)
        }
        .padding()
    }
    
    static var sampleView: some View {
        VStack(alignment: .center, spacing: 40) {
            RoundedBorderTextEditor(title: "A title", placeHolder: "A placeholder", text: .constant(""), error: nil)
            RoundedBorderTextEditor(placeHolder: "A placeholder", text: .constant("Some text"), error: nil)
            RoundedBorderTextEditor(title: "A title", placeHolder: "A placeholder", text: .constant("Some very long text used to check overlapping with the delete button"), error: "Some error text")
            RoundedBorderTextEditor(title: "A title", placeHolder: "A placeholder", text: .constant("Some very long text used to check overlapping with the delete button"), error: "Some error text")
                .disabled(true)
        }
    }
}
