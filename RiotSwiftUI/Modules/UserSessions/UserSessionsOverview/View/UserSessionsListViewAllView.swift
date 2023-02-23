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

struct UserSessionsListViewAllView: View {
    @Environment(\.theme) private var theme: ThemeSwiftUI

    let count: Int
    
    var onBackgroundTap: (() -> Void)?
    
    var body: some View {
        Button {
            onBackgroundTap?()
        } label: {
            Button(action: { onBackgroundTap?() }) {
                VStack(spacing: 0) {
                    HStack {
                        Text("View all (\(count))")
                            .font(theme.fonts.body)
                            .foregroundColor(theme.colors.accent)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Image(Asset.Images.chevron.name)
                    }
                    .padding(.vertical, 15)
                    .padding(.trailing, 20)
                    SeparatorLine()
                }
                .background(theme.colors.background)
                .padding(.leading, 72)
            }
        }
        .accessibilityIdentifier("ViewAllButton")
    }
}

struct UserSessionsListViewAllView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            UserSessionsListViewAllView(count: 8)
                .previewLayout(PreviewLayout.sizeThatFits)
                .theme(.light)
                .preferredColorScheme(.light)
            
            UserSessionsListViewAllView(count: 8)
                .previewLayout(PreviewLayout.sizeThatFits)
                .theme(.dark)
                .preferredColorScheme(.dark)
        }
    }
}
