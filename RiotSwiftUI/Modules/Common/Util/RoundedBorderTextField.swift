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
struct RoundedBorderTextField: View {
    
    // MARK: - Properties
    
    var title: String?
    var placeHolder: String
    @Binding var text: String
    @Binding var footerText: String?
    @Binding var isError: Bool
    var isFirstResponder = false

    var configuration: UIKitTextInputConfiguration = UIKitTextInputConfiguration()
    
    var onTextChanged: ((String) -> Void)?
    var onEditingChanged: ((Bool) -> Void)?

    // MARK: Private
    
    @State private var editing = false
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    // MARK: Setup
    
    init(title: String? = nil, placeHolder: String, text: Binding<String>, footerText: Binding<String?> = .constant(nil), isError: Binding<Bool> = .constant(false), isFirstResponder: Bool = false, configuration: UIKitTextInputConfiguration = UIKitTextInputConfiguration(), onTextChanged: ((String) -> Void)? = nil, onEditingChanged: ((Bool) -> Void)? = nil) {
        self.title = title
        self.placeHolder = placeHolder
        self._text = text
        self._footerText = footerText
        self._isError = isError
        self.isFirstResponder = isFirstResponder
        self.configuration = configuration
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
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeHolder)
                        .font(theme.fonts.callout)
                        .foregroundColor(theme.colors.tertiaryContent)
                        .lineLimit(1)
                }
                ThemableTextField(placeholder: "", text: $text, configuration: configuration, onEditingChanged: { edit in
                    self.editing = edit
                    onEditingChanged?(edit)
                })
                .makeFirstResponder(isFirstResponder)
                .onChange(of: text, perform: { newText in
                    onTextChanged?(newText)
                })
                .frame(height: 30)
                .modifier(ClearViewModifier(alignment: .center, text: $text))
            }
            .padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: text.isEmpty ? 8 : 0))
            .overlay(RoundedRectangle(cornerRadius: 8)
                        .stroke(editing ? theme.colors.accent : (footerText != nil && isError ? theme.colors.alert : theme.colors.quinaryContent), lineWidth: editing || (footerText != nil && isError) ? 2 : 1))

            if let footerText = self.footerText {
                Text(footerText)
                    .foregroundColor(isError ? theme.colors.alert : theme.colors.tertiaryContent)
                    .font(theme.fonts.footnote)
                    .multilineTextAlignment(.leading)
                    .padding(EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0))
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.2))
    }
}

// MARK: - Previews

@available(iOS 14.0, *)
struct TextFieldWithError_Previews: PreviewProvider {
    static var previews: some View {

        Group {
            VStack(alignment: .center, spacing: 40) {
                RoundedBorderTextField(title: "A title", placeHolder: "A placeholder", text: .constant(""), footerText: .constant(nil), isError: .constant(false))
                RoundedBorderTextField(placeHolder: "A placeholder", text: .constant("Some text"), footerText: .constant(nil), isError: .constant(false))
                RoundedBorderTextField(title: "A title", placeHolder: "A placeholder", text: .constant("Some very long text used to check overlapping with the delete button"), footerText: .constant("Some error text"), isError: .constant(true))
                RoundedBorderTextField(title: "A title", placeHolder: "A placeholder", text: .constant("Some very long text used to check overlapping with the delete button"), footerText: .constant("Some normal text"), isError: .constant(false))
            }
            
            VStack(alignment: .center, spacing: 20) {
                RoundedBorderTextField(title: "A title", placeHolder: "A placeholder", text: .constant(""), footerText: .constant(nil), isError: .constant(false))
                RoundedBorderTextField(placeHolder: "A placeholder", text: .constant("Some text"), footerText: .constant(nil), isError: .constant(false))
                RoundedBorderTextField(title: "A title", placeHolder: "A placeholder", text: .constant("Some very long text used to check overlapping with the delete button"), footerText: .constant("Some error text"), isError: .constant(true))
                RoundedBorderTextField(title: "A title", placeHolder: "A placeholder", text: .constant("Some very long text used to check overlapping with the delete button"), footerText: .constant("Some normal text"), isError: .constant(false))
            }.theme(.dark).preferredColorScheme(.dark)
        }
        .padding()
    }
}
