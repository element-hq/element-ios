//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct AuthenticationTermsListItem: View {
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme
    
    // MARK: Public
    
    @Binding var policy: AuthenticationTermsPolicy
    
    let action: () -> Void
    
    // MARK: - Views
    
    var body: some View {
        Button(action: action) {
            label
                .padding(.vertical, 14)
                .overlay(separator, alignment: .bottom)
        }
        .buttonStyle(FormItemButtonStyle())
    }
    
    /// The content to be shown in the list row.
    var label: some View {
        HStack(spacing: 16) {
            Toggle(VectorL10n.accept, isOn: $policy.accepted)
                .toggleStyle(AuthenticationTermsToggleStyle())
                .accessibilityLabel(VectorL10n.accept)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(policy.title)
                    .font(theme.fonts.body)
                    .foregroundColor(theme.colors.primaryContent)
                
                Text(policy.subtitle)
                    .font(theme.fonts.subheadline)
                    .foregroundColor(theme.colors.tertiaryContent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Image(systemName: "chevron.forward")
                .foregroundColor(theme.colors.tertiaryContent)
        }
        .padding(.horizontal, 16)
    }
    
    /// The separator shown beneath the item.
    var separator: some View {
        Rectangle()
            .frame(height: 1)
            .foregroundColor(theme.colors.system)
            .padding(.leading)
    }
}

struct Previews_AuthenticationTermsListItem_Previews: PreviewProvider {
    static var unaccepted = AuthenticationTermsPolicy(url: "",
                                                      title: "Terms and Conditions",
                                                      subtitle: "matrix.org")
    static var accepted = AuthenticationTermsPolicy(url: "",
                                                    title: "Terms and Conditions",
                                                    subtitle: "matrix.org",
                                                    accepted: true)
    static var previews: some View {
        VStack(spacing: 0) {
            AuthenticationTermsListItem(policy: .constant(unaccepted)) { }
            AuthenticationTermsListItem(policy: .constant(accepted)) { }
        }
    }
}
