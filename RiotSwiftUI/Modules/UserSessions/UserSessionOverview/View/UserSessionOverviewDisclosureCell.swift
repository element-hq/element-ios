//
// Copyright 2022 New Vector Ltd
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

struct UserSessionOverviewDisclosureCell: View {
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    let title: String
    var onBackgroundTap: (() -> Void)?
    
    var body: some View {
        Button(action: { onBackgroundTap?() }) {
            VStack(spacing: 0) {
                SeparatorLine()
                HStack {
                    Text(title)
                        .font(theme.fonts.body)
                        .foregroundColor(theme.colors.primaryContent)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Image(Asset.Images.chevron.name)
                }
                .padding(.vertical, 15)
                .padding(.horizontal, 16)
                SeparatorLine()
            }
            .background(theme.colors.background)
        }
    }
}

struct UserSessionOverviewDisclosureCell_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            UserSessionOverviewDisclosureCell(title: "Title")
                .theme(.light)
                .preferredColorScheme(.light)
            UserSessionOverviewDisclosureCell(title: "Title")
                .theme(.dark)
                .preferredColorScheme(.dark)
        }
    }
}
