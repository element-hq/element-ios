// 
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct VerificationRequiredBanner: View {
    // swiftlint:disable:next force_unwrapping
    static let learnMoreURL = URL(string: "https://docs.element.io/latest/element-support/device-verification/how-to-verify-devices")!
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    let verifyAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 0) {
                Text(VectorL10n.verificationRequiredBannerTitle)
                    .foregroundStyle(theme.colors.primaryContent)
                    .font(theme.fonts.bodySB)
                    .padding(.bottom, 4)
                
                Text(VectorL10n.verificationRequiredBannerDescription)
                    .foregroundStyle(theme.colors.secondaryContent)
                    .font(theme.fonts.subheadline)
                Link(VectorL10n.verificationRequiredBannerLearnMore, destination: Self.learnMoreURL)
                    .foregroundStyle(theme.colors.primaryContent)
                    .font(theme.fonts.subheadline.weight(.semibold))
            }
            Button(VectorL10n.verificationRequiredBannerVerifyButton) {
                verifyAction()
            }
            .buttonStyle(PrimaryActionButtonStyle(font: theme.fonts.bodySB))
        }
        .padding(16)
        .background(theme.colors.navigation)
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }
}

#Preview {
    VerificationRequiredBanner { }
}
