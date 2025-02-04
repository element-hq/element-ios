//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct OptionButton: View {
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
    let detailMessage: String?
    let action: () -> Void
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    // MARK: Public
    
    var body: some View {
        Button(action: action, label: {
            HStack {
                if let image = icon {
                    Image(uiImage: image).renderingMode(.template).resizable().frame(width: 24, height: 24).foregroundColor(theme.colors.secondaryContent)
                }
                VStack(alignment: .leading, spacing: nil) {
                    Text(title).font(theme.fonts.bodySB).foregroundColor(theme.colors.primaryContent)
                    if let detail = detailMessage {
                        Text(detail).font(theme.fonts.caption1).foregroundColor(theme.colors.secondaryContent)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 16, weight: .regular)).foregroundColor(theme.colors.quarterlyContent)
            }
            .padding(EdgeInsets(top: 15, leading: 16, bottom: 15, trailing: 16))
            .background(theme.colors.quinaryContent)
            .foregroundColor(theme.colors.secondaryContent)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        })
        .buttonStyle(Style())
    }
}

// MARK: - Previews

struct OptionButton_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VStack {
                OptionButton(icon: Asset.Images.spaceTypeIcon.image, title: "A title", detailMessage: "Some details for this option", action: { }).theme(.light)
                OptionButton(icon: nil, title: "A title", detailMessage: "Some details for this option", action: { }).theme(.light)
                OptionButton(icon: nil, title: "A title", detailMessage: nil, action: { }).theme(.light)
            }
            VStack {
                OptionButton(icon: Asset.Images.spaceTypeIcon.image, title: "A title", detailMessage: "Some details for this option", action: { }).theme(.dark)
                OptionButton(icon: nil, title: "A title", detailMessage: "Some details for this option", action: { }).theme(.dark)
                OptionButton(icon: nil, title: "A title", detailMessage: nil, action: { }).theme(.dark)
            }.preferredColorScheme(.dark)
        }
        .padding()
    }
}
