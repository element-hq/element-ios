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

struct ThemableNavigationBar: View {
    // MARK: - Style
    
    // MARK: - Properties
    
    let title: String?
    let showBackButton: Bool
    let backAction: () -> Void
    let closeAction: () -> Void

    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    // MARK: Public
    
    @ViewBuilder
    var body: some View {
        HStack {
            Button(action: { backAction() }) {
                Image(uiImage: Asset.Images.spacesModalBack.image)
                    .renderingMode(.template)
                    .foregroundColor(theme.colors.secondaryContent)
            }
            .isHidden(!showBackButton)
            Spacer()
            if let title = title {
                Text(title).font(theme.fonts.headline)
                    .foregroundColor(theme.colors.primaryContent)
            }
            Spacer()
            Button(action: { closeAction() }) {
                Image(uiImage: Asset.Images.spacesModalClose.image)
                    .renderingMode(.template)
                    .foregroundColor(theme.colors.secondaryContent)
            }
        }
        .padding(.horizontal)
        .frame(height: 44)
        .background(theme.colors.background)
    }
}

// MARK: - Previews

struct NavigationBar_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VStack {
                ThemableNavigationBar(title: nil, showBackButton: true, backAction: { }, closeAction: { })
                ThemableNavigationBar(title: "Some Title", showBackButton: true, backAction: { }, closeAction: { })
                ThemableNavigationBar(title: nil, showBackButton: false, backAction: { }, closeAction: { })
                ThemableNavigationBar(title: "Some Title", showBackButton: false, backAction: { }, closeAction: { })
            }
            VStack {
                ThemableNavigationBar(title: nil, showBackButton: true, backAction: { }, closeAction: { }).theme(.dark)
                ThemableNavigationBar(title: "Some Title", showBackButton: true, backAction: { }, closeAction: { }).theme(.dark)
                ThemableNavigationBar(title: nil, showBackButton: false, backAction: { }, closeAction: { }).theme(.dark)
                ThemableNavigationBar(title: "Some Title", showBackButton: false, backAction: { }, closeAction: { }).theme(.dark)
            }.preferredColorScheme(.dark)
        }
        .padding()
    }
}
