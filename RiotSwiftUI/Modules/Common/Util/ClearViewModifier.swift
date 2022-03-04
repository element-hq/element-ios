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
extension ThemableTextField {
    func showClearButton(text: Binding<String>, alignement: VerticalAlignment = .center) -> some View {
        return modifier(ClearViewModifier(alignment: alignement, text: text))
    }
}

@available(iOS 14.0, *)
extension ThemableTextEditor {
    func showClearButton(text: Binding<String>, alignement: VerticalAlignment = .top) -> some View {
        return modifier(ClearViewModifier(alignment: alignement, text: text))
    }
}

/// `ClearViewModifier` aims to add a clear button (e.g. `x` button) on the right side of any text editing view
@available(iOS 14.0, *)
struct ClearViewModifier: ViewModifier
{
    // MARK: - Properties
    
    let alignment: VerticalAlignment
    
    // MARK: - Bindings
    
    @Binding var text: String
    
    // MARK: - Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI

    // MARK: - Public
    
    public func body(content: Content) -> some View
    {
        HStack(alignment: alignment) {
            content
            if !text.isEmpty {
                Button(action: {
                    self.text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .renderingMode(.template)
                        .foregroundColor(theme.colors.quarterlyContent)
                }
                .padding(EdgeInsets(top: alignment == .top ? 8 : 0, leading: 0, bottom: alignment == .bottom ? 8 : 0, trailing: 8))
            }
        }
    }
}
