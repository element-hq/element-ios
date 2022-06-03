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
    
    var title: String? = nil
    let placeHolder: String
    @Binding var text: String
    var footerText: String? = nil
    var isError: Bool = false
    var isFirstResponder = false

    var configuration: UIKitTextInputConfiguration = UIKitTextInputConfiguration()
    
    var onTextChanged: ((String) -> Void)? = nil
    var onEditingChanged: ((Bool) -> Void)? = nil
    var onCommit: (() -> Void)? = nil

    // MARK: Private
    
    @State private var editing = false
    
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
            
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeHolder)
                        .font(theme.fonts.callout)
                        .foregroundColor(theme.colors.tertiaryContent)
                        .lineLimit(1)
                        .accessibilityHidden(true)
                }
                
                ThemableTextField(placeholder: "", text: $text, configuration: configuration, onEditingChanged: { edit in
                    self.editing = edit
                    onEditingChanged?(edit)
                }, onCommit: {
                    onCommit?()
                })
                .makeFirstResponder(isFirstResponder)
                .showClearButton(isEnabled, text: $text)
                .onChange(of: text) { newText in
                    onTextChanged?(newText)
                }
                .frame(height: 30)
                .allowsHitTesting(isEnabled)
                .opacity(isEnabled ? 1 : 0.5)
                .accessibilityLabel(text.isEmpty ? placeHolder : "")
            }
            .padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: text.isEmpty ? 8 : 0))
            .background(RoundedRectangle(cornerRadius: 8).fill(theme.colors.background))
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
            sampleView.theme(.light).preferredColorScheme(.light)
            sampleView.theme(.dark).preferredColorScheme(.dark)
        }
        .padding()
    }
    
    static var sampleView: some View {
        VStack(alignment: .center, spacing: 20) {
            RoundedBorderTextField(title: "A title", placeHolder: "A placeholder", text: .constant(""), footerText: nil, isError: false)
            RoundedBorderTextField(placeHolder: "A placeholder", text: .constant("Some text"), footerText: nil, isError: false)
            RoundedBorderTextField(title: "A title", placeHolder: "A placeholder", text: .constant("Some very long text used to check overlapping with the delete button"), footerText: "Some error text", isError: true)
            RoundedBorderTextField(title: "A title", placeHolder: "A placeholder", text: .constant("Some very long text used to check overlapping with the delete button"), footerText: "Some normal text", isError: false)
            RoundedBorderTextField(title: "A title", placeHolder: "A placeholder", text: .constant("Some very long text used to check overlapping with the delete button"), footerText: "Some normal text", isError: false)
                .disabled(true)
        }
    }
}
