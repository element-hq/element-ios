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

struct MatrixItemChooserSectionHeader: View {

    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    // MARK: Public
    
    let title: String?
    let infoText: String?
    
    @ViewBuilder
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let titleText = title {
                Text(titleText)
                    .foregroundColor(theme.colors.secondaryContent)
                    .font(theme.fonts.footnoteSB)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibility(identifier: "headerTitleText")
            }
            if let infoText = infoText {
                HStack(spacing: 16) {
                    Image(uiImage: Asset.Images.roomAccessInfoHeaderIcon.image)
                        .renderingMode(.template)
                        .foregroundColor(theme.colors.secondaryContent)
                    Text(infoText)
                        .foregroundColor(theme.colors.secondaryContent)
                        .font(theme.fonts.footnote)
                        .accessibility(identifier: "headerInfoText")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
                .padding(.horizontal)
                .background(theme.colors.navigation)
                .cornerRadius(8)
            }
        }
        .padding()
    }
}

// MARK: - Previews

struct MatrixItemChooserSectionHeader_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VStack(spacing: 16) {
                MatrixItemChooserSectionHeader(title: nil, infoText: nil)
                MatrixItemChooserSectionHeader(title: "Some Title", infoText: nil)
                MatrixItemChooserSectionHeader(title: "Some Title", infoText: "A very long info text in order to see if it's well handled by the UI")
            }.theme(.light).preferredColorScheme(.light)
            VStack(spacing: 16) {
                MatrixItemChooserSectionHeader(title: nil, infoText: nil)
                MatrixItemChooserSectionHeader(title: "Some Title", infoText: nil)
                MatrixItemChooserSectionHeader(title: "Some Title", infoText: "A very long info text in order to see if it's well handled by the UI")
            }.theme(.dark).preferredColorScheme(.dark)
        }
    }
}
