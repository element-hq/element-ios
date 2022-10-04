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
