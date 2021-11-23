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
struct NextViewModifier: ViewModifier
{
    // MARK: - Properties
    
    let alignment: Alignment
    
    // MARK: - Bindings
    
    @Binding var isEditing: Bool
    
    // MARK: - Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI

    // MARK: - Public
    
    public func body(content: Content) -> some View
    {
        ZStack(alignment: alignment) {
            content
            if isEditing {
                Button(action: {
                    if !ResponderManager.makeActiveNextResponder() {
                        ResponderManager.resignFirstResponder()
                    }
                }) {
                    Image(systemName: "arrow.down.circle.fill")
                        .renderingMode(.template)
                        .foregroundColor(theme.colors.quarterlyContent)
                }
                .padding(EdgeInsets(top: alignment.vertical == .top ? 8 : 0, leading: 0, bottom: alignment.vertical == .bottom ? 8 : 0, trailing: 8))
            }
        }
    }
}

