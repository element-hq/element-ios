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
