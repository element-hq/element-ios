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

import Foundation
import SwiftUI

@available(iOS 14.0, *)
/// A bordered style of text input
///
/// As defined in:
/// https://www.figma.com/file/X4XTH9iS2KGJ2wFKDqkyed/Compound?node-id=2039%3A26415
struct BorderedInputFieldStyle: TextFieldStyle {
    
    @Environment(\.theme) var theme: ThemeSwiftUI
    @Environment(\.isEnabled) var isEnabled: Bool
    
    var isEditing: Bool = false
    var isError: Bool = false
    
    private var borderColor: Color {
        if !isEnabled {
            return theme.colors.quinaryContent
        } else if isError {
            return theme.colors.alert
        } else if isEditing {
            return theme.colors.accent
        }
        return theme.colors.quarterlyContent
    }
    
    private var accentColor: Color {
        if isError {
            return theme.colors.alert
        }
        return theme.colors.accent
    }
    
    private var textColor: Color {
        if !isEnabled {
            return theme.colors.quarterlyContent
        }
        return theme.colors.primaryContent
    }
    
    private var backgroundColor: Color {
        if !isEnabled && (theme.identifier == ThemeIdentifier.dark) {
            return theme.colors.quinaryContent
        }
        return theme.colors.background
    }
    
    private var borderWidth: CGFloat {
        return isEditing || isError ? 2 : 1.5
    }
    
    func _body(configuration: TextField<_Label>) -> some View {
        let rect = RoundedRectangle(cornerRadius: 8)
        return configuration
            .font(theme.fonts.callout)
            .foregroundColor(textColor)
            .accentColor(accentColor)
            .frame(height: 48)
            .padding(.horizontal, 8)
            .background(backgroundColor)
            .clipShape(rect)
            .overlay(rect.stroke(borderColor, lineWidth: borderWidth))
    }
}

@available(iOS 14.0, *)
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
