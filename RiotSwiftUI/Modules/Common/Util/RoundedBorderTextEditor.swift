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

@available(iOS 14.0, *)
struct RoundedBorderTextEditor: View {
    
    // MARK: - Properties
    
    var title: String?
    var placeHolder: String
    @Binding var text: String
    var textMaxHeight: CGFloat?
    @Binding var error: String?
    
    var onTextChanged: ((String) -> Void)?
    var onEditingChanged: ((Bool) -> Void)?

    @State private var editing = false
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    // MARK: Setup
    
    init(title: String? = nil,
         placeHolder: String,
         text: Binding<String>,
         textMaxHeight: CGFloat? = nil,
         error: Binding<String?> = .constant(nil),
         onTextChanged: ((String) -> Void)? = nil,
         onEditingChanged: ((Bool) -> Void)? = nil) {
        self.title = title
        self.placeHolder = placeHolder
        self._text = text
        self.textMaxHeight = textMaxHeight
        self._error = error
        self.onTextChanged = onTextChanged
        self.onEditingChanged = onEditingChanged
    }
    
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
                ThemableTextEditor(text: $text, onEditingChanged: { edit in
                    self.editing = edit
                    onEditingChanged?(edit)
                })
                .modifier(ClearViewModifier(alignment: .top, text: $text))
                // Found no good solution here. Hidding next button for the moment
//                .modifier(NextViewModifier(alignment: .bottomTrailing, isEditing: $editing))
                .padding(EdgeInsets(top: 2, leading: 6, bottom: 0, trailing: 0))
                .onChange(of: text, perform: { newText in
                    onTextChanged?(newText)
                })
            }
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

@available(iOS 14.0, *)
struct ThemableTextEditor_Previews: PreviewProvider {
    static var previews: some View {

        Group {
            VStack(alignment: .center, spacing: 40) {
                RoundedBorderTextEditor(title: "A title", placeHolder: "A placeholder", text: .constant(""), error: .constant(nil))
                RoundedBorderTextEditor(placeHolder: "A placeholder", text: .constant("Some text"), error: .constant(nil))
                RoundedBorderTextEditor(title: "A title", placeHolder: "A placeholder", text: .constant("Some very long text used to check overlapping with the delete button"), error: .constant("Some error text"))
            }
            VStack(alignment: .center, spacing: 40) {
                RoundedBorderTextEditor(title: "A title", placeHolder: "A placeholder", text: .constant(""), error: .constant(nil))
                RoundedBorderTextEditor(placeHolder: "A placeholder", text: .constant("Some text"), error: .constant(nil))
                RoundedBorderTextEditor(title: "A title", placeHolder: "A placeholder", text: .constant("Some text"), error: .constant("Some error text"))
            }
            .theme(.dark).preferredColorScheme(.dark)
        }
        .padding()
    }
}
