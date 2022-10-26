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

struct UserOtherSessionsHeaderViewData: Hashable {
    let title: String?
    let subtitle: String
    let iconName: String?
}

struct UserOtherSessionsHeaderView: View {
    private var backgroundShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 8)
    }
    
    @Environment(\.theme) private var theme
    
    let viewData: UserOtherSessionsHeaderViewData
    var onLearnMoreAction: (() -> Void)?
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            if let iconName = viewData.iconName {
                Image(iconName)
                    .frame(width: 40, height: 40)
                    .background(theme.colors.background)
                    .clipShape(backgroundShape)
                    .shapedBorder(color: theme.colors.quinaryContent, borderWidth: 1.0, shape: backgroundShape)
                    .padding(.trailing, 16)
            }
            VStack(alignment: .leading, spacing: 0, content: {
                if let title = viewData.title {
                    Text(title)
                        .font(theme.fonts.calloutSB)
                        .foregroundColor(theme.colors.primaryContent)
                        .padding(.vertical, 9.0)
                }
                InlineTextButton(viewData.subtitle, tappableText: VectorL10n.userSessionLearnMore, alwaysCallAction: false) {
                    onLearnMoreAction?()
                }
                .font(theme.fonts.footnote)
                .foregroundColor(theme.colors.secondaryContent)
                .padding(.bottom, 20.0)
            })
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
    }
}

// MARK: - Previews

struct UserOtherSessionsHeaderView_Previews: PreviewProvider {
    private static let headerWithTitleSubtitleIcon = UserOtherSessionsHeaderViewData(title: VectorL10n.userSessionsOverviewSecurityRecommendationsInactiveTitle,
                                                                                     subtitle: VectorL10n.userSessionsOverviewSecurityRecommendationsInactiveInfo,
                                                                                     iconName: Asset.Images.userOtherSessionsInactive.name)
    
    private static let headerWithSubtitle = UserOtherSessionsHeaderViewData(title: nil,
                                                                            subtitle: VectorL10n.userSessionsOverviewOtherSessionsSectionInfo,
                                                                            iconName: nil)
    
    private static let inactiveSessionViewData = UserOtherSessionsHeaderViewData(title: VectorL10n.userSessionsOverviewSecurityRecommendationsInactiveTitle,
                                                                                 subtitle: VectorL10n.userSessionsOverviewSecurityRecommendationsInactiveInfo,
                                                                                 iconName: Asset.Images.userOtherSessionsInactive.name)
    static var previews: some View {
        Group {
            VStack {
                Divider()
                UserOtherSessionsHeaderView(viewData: self.headerWithTitleSubtitleIcon)
                Divider()
                UserOtherSessionsHeaderView(viewData: self.headerWithSubtitle)
                Divider()
            }
            .theme(.light)
            .preferredColorScheme(.light)
            VStack {
                Divider()
                UserOtherSessionsHeaderView(viewData: self.headerWithTitleSubtitleIcon)
                Divider()
                UserOtherSessionsHeaderView(viewData: self.headerWithSubtitle)
                Divider()
            }
            .theme(.dark)
            .preferredColorScheme(.dark)
        }
    }
}
