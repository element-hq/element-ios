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

/// Adds a reveal password button (e.g. an eye button) on the
/// right side of the view. For use with `ThemableTextField`.
struct PasswordButtonModifier: ViewModifier {
    // MARK: - Properties
    
    let text: String
    @Binding var isSecureTextVisible: Bool
    let alignment: VerticalAlignment
    
    // MARK: - Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    @ScaledMetric private var iconSize = 16

    // MARK: - Public
    
    public func body(content: Content) -> some View {
        HStack(alignment: .center) {
            content
            
            if !text.isEmpty {
                Button { isSecureTextVisible.toggle() } label: {
                    Image(Asset.Images.authenticationRevealPassword.name)
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: iconSize, height: iconSize)
                        .foregroundColor(theme.colors.secondaryContent)
                }
                .padding(.top, alignment == .top ? 8 : 0)
                .padding(.bottom, alignment == .bottom ? 8 : 0)
                .padding(.trailing, 12)
            }
        }
    }
}
