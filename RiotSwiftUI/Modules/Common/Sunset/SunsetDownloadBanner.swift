//
// Copyright 2025 New Vector Ltd
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

struct SunsetDownloadBanner: View {
    @Environment(\.theme) private var theme
    
    let replacementApp: BuildSettings.ReplacementApp
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 13) {
                Image(Asset.Images.sunsetBannerIcon.name)
                    .clipShape(RoundedRectangle(cornerRadius: 15.2))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(VectorL10n.sunsetDownloadBannerTitle(replacementApp.name))
                        .font(theme.fonts.title3SB)
                        .foregroundStyle(theme.colors.primaryContent)
                    
                    Text(VectorL10n.sunsetDownloadBannerMessage)
                        .font(theme.fonts.callout)
                        .foregroundStyle(theme.colors.secondaryContent)
                    
                    // Using a button rather than an attributed string so that it animates on tap.
                    Button(VectorL10n.sunsetDownloadBannerLearnMore) {
                        UIApplication.shared.open(replacementApp.learnMoreURL)
                    }
                    .font(theme.fonts.bodySB)
                    .tint(theme.colors.links)
                    .padding(.top, 4)
                }
                .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(BannerButtonStyle())
    }
}

private struct BannerButtonStyle: ButtonStyle {
    @Environment(\.theme) private var theme
    
    let bannerShape = RoundedRectangle(cornerRadius: 8)
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(12)
            .shapedBorder(color: theme.colors.quarterlyContent, borderWidth: 1.5, shape: bannerShape)
            .background(configuration.isPressed ? theme.colors.system : theme.colors.background, in: bannerShape)
            .contentShape(bannerShape)
    }
}

struct SunsetDownloadBanner_Previews: PreviewProvider {
    static var previews: some View {
        SunsetDownloadBanner(replacementApp: BuildSettings.replacementApp!) { }
            .padding(.horizontal)
    }
}
