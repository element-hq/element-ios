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

import Foundation
import SwiftUI

struct SecurityRecommendationCard: View {
    enum Style {
        case unverified
        case inactive
    }
    
    @Environment(\.theme) var theme: ThemeSwiftUI
    
    let style: SecurityRecommendationCard.Style
    let sessionCount: Int
    let action: () -> Void
    
    var body: some View {
        HStack(alignment: .top) {
            Image(iconName)
            VStack(alignment: .leading, spacing: 16.0) {
                VStack(alignment: .leading, spacing: 8.0) {
                    Text(title)
                        .font(theme.fonts.calloutSB)
                        .foregroundColor(theme.colors.primaryContent)
                    
                    Text(subtitle)
                        .font(theme.fonts.footnote)
                        .foregroundColor(theme.colors.secondaryContent)
                }
                
                Button {
                    action()
                } label: {
                    Text(buttonTitle)
                        .font(theme.fonts.body)
                }
                .foregroundColor(theme.colors.accent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(theme.colors.background)
        .clipShape(backgroundShape)
        .shapedBorder(color: theme.colors.quinaryContent, borderWidth: 1.0, shape: backgroundShape)
    }
    
    private var backgroundShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 8)
    }
    
    private var iconName: String {
        switch style {
        case .unverified:
            return Asset.Images.userSessionsUnverified.name
        case .inactive:
            return Asset.Images.userSessionsInactive.name
        }
    }
    
    private var title: String {
        switch style {
        case .unverified:
            return VectorL10n.userSessionsOverviewSecurityRecommendationsUnverifiedTitle
        case .inactive:
            return VectorL10n.userSessionsOverviewSecurityRecommendationsInactiveTitle
        }
    }
    
    private var subtitle: String {
        switch style {
        case .unverified:
            return VectorL10n.userSessionsOverviewSecurityRecommendationsUnverifiedInfo
        case .inactive:
            return VectorL10n.userSessionsOverviewSecurityRecommendationsInactiveInfo
        }
    }
    
    private var buttonTitle: String {
        VectorL10n.userSessionsViewAllAction(sessionCount)
    }
}

struct SecurityRecommendationCard_Previews: PreviewProvider {
    static var previews: some View {
        body.theme(.light).preferredColorScheme(.light)
        body.theme(.dark).preferredColorScheme(.dark)
    }

    @ViewBuilder
    static var body: some View {
        VStack {
            SecurityRecommendationCard(style: .unverified, sessionCount: 4, action: { })
            SecurityRecommendationCard(style: .inactive, sessionCount: 100, action: { })
        }
    }
}
