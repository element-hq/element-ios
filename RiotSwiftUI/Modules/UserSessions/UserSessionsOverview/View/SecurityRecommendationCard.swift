//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
        HStack(alignment: .top, spacing: 16.0) {
            Image(iconName)
            VStack(alignment: .leading, spacing: 16.0) {
                VStack(alignment: .leading, spacing: 8.0) {
                    Text(title)
                        .font(theme.fonts.headline)
                        .foregroundColor(theme.colors.primaryContent)
                    
                    Text(subtitle)
                        .font(theme.fonts.footnote)
                        .foregroundColor(theme.colors.secondaryContent)
                }
                
                Text(buttonTitle)
                    .font(theme.fonts.body)
                    .foregroundColor(theme.colors.accent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(theme.colors.background)
        .clipShape(backgroundShape)
        .shapedBorder(color: theme.colors.quinaryContent, borderWidth: 0.5, shape: backgroundShape)
        .onTapGesture {
            action()
        }
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
