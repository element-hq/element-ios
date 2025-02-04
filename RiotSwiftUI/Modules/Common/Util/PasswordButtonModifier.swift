//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
