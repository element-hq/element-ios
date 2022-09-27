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
