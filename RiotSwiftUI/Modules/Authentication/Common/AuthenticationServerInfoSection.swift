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
