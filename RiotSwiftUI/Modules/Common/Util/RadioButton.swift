//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct RadioButton: View {
    // MARK: - Properties
    
    var title: String
    var selected: Bool
    let action: () -> Void
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    // MARK: Public
    
    var body: some View {
        Button(action: action, label: {
            HStack {
                Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                    .renderingMode(.template)
                    .resizable().frame(width: 20, height: 20)
                    .foregroundColor(selected ? theme.colors.accent : theme.colors.tertiaryContent)
                Text(title)
                    .font(theme.fonts.callout)
                    .foregroundColor(theme.colors.primaryContent)
                Spacer()
            }
            .padding(EdgeInsets(top: 3, leading: 3, bottom: 3, trailing: 3))
            .background(Color.clear)
        })
    }
}

// MARK: - Previews

struct RadioButton_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            buttonGroup.theme(.light)
            buttonGroup.theme(.dark).preferredColorScheme(.dark)
        }
        .padding()
    }
    
    static var buttonGroup: some View {
        VStack {
            RadioButton(title: "A title", selected: false, action: { })
            RadioButton(title: "A title", selected: true, action: { })
        }
    }
}
