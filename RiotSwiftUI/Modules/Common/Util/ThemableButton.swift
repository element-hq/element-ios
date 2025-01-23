//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct ThemableButton: View {
    // MARK: - Style
    
    private struct Style: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.97 : 1)
                .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
        }
    }

    // MARK: - Properties
    
    let icon: UIImage?
    let title: String
    let action: () -> Void
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    // MARK: Public
    
    var body: some View {
        Button(action: action, label: {
            HStack {
                Spacer()
                if let icon = self.icon {
                    Image(uiImage: icon).renderingMode(.template).resizable().frame(width: 24, height: 24).foregroundColor(theme.colors.background)
                }
                Text(title).font(theme.fonts.bodySB).foregroundColor(theme.colors.background)
                Spacer()
            }
            .padding()
            .background(theme.colors.accent)
            .foregroundColor(theme.colors.background)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        })
        .buttonStyle(Style())
        .frame(height: 44)
    }
}

// MARK: - Previews

struct ThemableButton_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VStack(alignment: .center, spacing: 20) {
                ThemableButton(icon: Asset.Images.spaceTypeIcon.image, title: "A title", action: { }).theme(.light).preferredColorScheme(.light)
                ThemableButton(icon: nil, title: "A title", action: { }).theme(.light).preferredColorScheme(.light)
            }
            VStack(alignment: .center, spacing: 20) {
                ThemableButton(icon: Asset.Images.spaceTypeIcon.image, title: "A title", action: { }).theme(.dark).preferredColorScheme(.dark)
                ThemableButton(icon: nil, title: "A title", action: { }).theme(.dark).preferredColorScheme(.dark)
            }
        }
        .padding()
    }
}
