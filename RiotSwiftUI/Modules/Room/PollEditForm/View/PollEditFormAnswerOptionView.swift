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

struct PollEditFormAnswerOptionView: View {
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    @State private var focused = false
    
    @Binding var text: String
    
    let index: Int
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8.0) {
            Text(VectorL10n.pollEditFormOptionNumber(index + 1))
                .font(theme.fonts.subheadline)
                .foregroundColor(theme.colors.primaryContent)
            
            HStack(spacing: 16.0) {
                TextField(VectorL10n.pollEditFormInputPlaceholder, text: $text, onEditingChanged: { edit in
                    self.focused = edit
                })
                .textFieldStyle(BorderedInputFieldStyle(isEditing: focused))
                Button(action: onDelete) {
                    Image(uiImage: Asset.Images.pollDeleteOptionIcon.image)
                }
                .accessibilityIdentifier("Delete answer option")
            }
        }
    }
}

struct PollEditFormAnswerOptionView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 32.0) {
            PollEditFormAnswerOptionView(text: Binding.constant(""), index: 0) { }
            PollEditFormAnswerOptionView(text: Binding.constant("Test"), index: 5) { }
        }
    }
}
