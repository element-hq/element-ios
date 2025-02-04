//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// A view that shows information about the chosen homeserver,
/// along with an edit button to pick a different one.
struct AuthenticationServerInfoSection: View {
    // MARK: - Private
    
    @Environment(\.theme) private var theme
    
    // MARK: - Public
    
    let address: String
    let flow: AuthenticationFlow
    let editAction: () -> Void
    
    var title: String {
        flow == .login ? VectorL10n.authenticationServerInfoTitleLogin : VectorL10n.authenticationServerInfoTitle
    }
    
    // MARK: - Views
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(theme.fonts.subheadline)
                .foregroundColor(theme.colors.secondaryContent)
            
            HStack {
                Text(address)
                    .font(theme.fonts.body)
                    .foregroundColor(theme.colors.primaryContent)
                
                Spacer()
                
                Button(action: editAction) {
                    Text(VectorL10n.edit)
                        .font(theme.fonts.body)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(theme.colors.accent))
                }
            }
        }
    }
}
