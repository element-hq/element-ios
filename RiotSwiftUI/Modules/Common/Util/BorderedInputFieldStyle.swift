//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import Introspect
import SwiftUI

/// A bordered style of text input
///
/// As defined in:
/// https://www.figma.com/file/X4XTH9iS2KGJ2wFKDqkyed/Compound?node-id=2039%3A26415
struct BorderedInputFieldStyle: TextFieldStyle {
    @Environment(\.theme) private var theme: ThemeSwiftUI
    @Environment(\.isEnabled) private var isEnabled: Bool
    
    var isEditing = false
    var isError = false
    
    private var borderColor: Color {
        if isError {
            return theme.colors.alert
        } else if isEditing {
            return theme.colors.accent
        }
        return theme.colors.quinaryContent
    }
    
    private var accentColor: Color {
        if isError {
            return theme.colors.alert
        }
        return theme.colors.accent
    }
    
    private var textColor: Color {
        if theme.identifier == ThemeIdentifier.dark {
            return (isEnabled ? theme.colors.primaryContent : theme.colors.tertiaryContent)
        } else {
            return (isEnabled ? theme.colors.primaryContent : theme.colors.quarterlyContent)
        }
    }
    
    private var backgroundColor: Color {
        if !isEnabled, theme.identifier == ThemeIdentifier.dark {
            return theme.colors.quinaryContent
        }
        return theme.colors.background
    }
    
    private var placeholderColor: Color {
        theme.colors.tertiaryContent
    }
        
    private var borderWidth: CGFloat {
        isEditing || isError ? 2.0 : 1.5
    }
    
    func _body(configuration: TextField<_Label>) -> some View {
        let rect = RoundedRectangle(cornerRadius: 8.0)
        return configuration
            .font(theme.fonts.callout)
            .foregroundColor(textColor)
            .accentColor(accentColor)
            .frame(height: 48.0)
            .padding(.horizontal, 8.0)
            .background(backgroundColor)
            .clipShape(rect)
            .overlay(rect.stroke(borderColor, lineWidth: borderWidth))
            .introspectTextField { textField in
                textField.returnKeyType = .done
                textField.clearButtonMode = .whileEditing
                textField.attributedPlaceholder = NSAttributedString(string: textField.placeholder ?? "",
                                                                     attributes: [NSAttributedString.Key.foregroundColor: UIColor(placeholderColor)])
            }
    }
}

struct BorderedInputFieldStyle_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VStack {
                TextField("Placeholder", text: .constant(""))
                    .textFieldStyle(BorderedInputFieldStyle())
                TextField("Placeholder", text: .constant(""))
                    .textFieldStyle(BorderedInputFieldStyle(isEditing: true))
                TextField("Placeholder", text: .constant("Web"))
                    .textFieldStyle(BorderedInputFieldStyle())
                TextField("Placeholder", text: .constant("Web"))
                    .textFieldStyle(BorderedInputFieldStyle(isEditing: true))
                TextField("Placeholder", text: .constant("Web"))
                    .textFieldStyle(BorderedInputFieldStyle())
                    .disabled(true)
                TextField("Placeholder", text: .constant("Web"))
                    .textFieldStyle(BorderedInputFieldStyle(isEditing: true, isError: true))
            }
            .padding()
            VStack {
                TextField("Placeholder", text: .constant(""))
                    .textFieldStyle(BorderedInputFieldStyle())
                TextField("Placeholder", text: .constant(""))
                    .textFieldStyle(BorderedInputFieldStyle(isEditing: true))
                TextField("Placeholder", text: .constant("Web"))
                    .textFieldStyle(BorderedInputFieldStyle())
                TextField("Placeholder", text: .constant("Web"))
                    .textFieldStyle(BorderedInputFieldStyle(isEditing: true))
                TextField("Placeholder", text: .constant("Web"))
                    .textFieldStyle(BorderedInputFieldStyle())
                    .disabled(true)
                TextField("Placeholder", text: .constant("Web"))
                    .textFieldStyle(BorderedInputFieldStyle(isEditing: true, isError: true))
            }
            .padding()
            .theme(ThemeIdentifier.dark)
        }
    }
}
