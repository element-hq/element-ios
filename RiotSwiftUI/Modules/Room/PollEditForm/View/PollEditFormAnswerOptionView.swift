//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
