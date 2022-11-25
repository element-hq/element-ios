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
struct MessageContextMenuListRow: View {

    // MARK: - Properties
    
    let item: MessageContextMenuItem
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    private var foregroundColor: Color {
        var color = item.attributes.contains(.destructive) ? theme.colors.alert : theme.colors.primaryContent
        if item.attributes.contains(.disabled) {
            color = color.opacity(0.3)
        }
        return color
    }
    
    // MARK: Public
    
    @ViewBuilder
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(item.title)
                    .foregroundColor(foregroundColor)
                    .font(theme.fonts.callout)
                    .accessibility(identifier: "itemTitleText")
                Spacer()
                if let image = item.image {
                    Image(uiImage: image)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(foregroundColor)
                        .frame(width: 16, height: 16)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            Divider().background(theme.colors.quarterlyContent)
        }
        .background(VisualEffectView(effect: UIBlurEffect(style: .systemMaterial)))
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Previews

@available(iOS 14.0, *)
struct MessageContextMenuListRow_Previews: PreviewProvider {
    static var previews: some View {
        MessageContextMenuListRow(item: MessageContextMenuItem(title: "Some title", type: .encryptionInfo)).theme(.light)
    }
}
