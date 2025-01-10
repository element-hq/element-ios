// 
// Copyright 2025 New Vector Ltd
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

struct SunsetOIDCRegistrationBanner: View {
    @Environment(\.theme) private var theme
    
    let homeserverAddress: String
    let replacementApp: BuildSettings.ReplacementApp
    
    private let bannerShape = RoundedRectangle(cornerRadius: 8)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label {
                Text(VectorL10n.sunsetDelegatedOidcRegistrationNotSupportedTitle(homeserverAddress))
            } icon: {
                Image(systemName: "exclamationmark.circle.fill")
            }
            .font(theme.fonts.callout.bold())
            .foregroundStyle(theme.colors.alert)
            
            Label {
                Text(VectorL10n.sunsetDelegatedOidcRegistrationNotSupportedMessage(replacementApp.name, homeserverAddress))
                    .font(theme.fonts.footnote)
            } icon: {
                // Invisible Icon to align the Text with the one above.
                Image(systemName: "circle")
                    .font(theme.fonts.callout.bold())
                    .hidden()
            }
            .foregroundStyle(theme.colors.primaryContent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(theme.colors.alert.opacity(0.05), in: bannerShape)
        .shapedBorder(color: theme.colors.alert.opacity(0.5), borderWidth: 2, shape: bannerShape)
    }
}

struct SunsetRegistrationAlert_Previews: PreviewProvider {
    static var previews: some View {
        SunsetOIDCRegistrationBanner(homeserverAddress: "beta.matrix.org",
                                replacementApp: BuildSettings.replacementApp!)
            .padding(.horizontal)
    }
}
