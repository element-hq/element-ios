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
    let showMatrixDotOrgInfo: Bool
    let editAction: () -> Void
    
    // MARK: - Views
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(VectorL10n.authenticationServerInfoTitle)
                .font(theme.fonts.subheadline)
                .foregroundColor(theme.colors.secondaryContent)
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(address)
                        .font(theme.fonts.body)
                        .foregroundColor(theme.colors.primaryContent)
                    
                    if showMatrixDotOrgInfo {
                        Text(VectorL10n.authenticationServerInfoMatrixDescription)
                            .font(theme.fonts.caption1)
                            .foregroundColor(theme.colors.tertiaryContent)
                            .accessibilityIdentifier("serverDescriptionText")
                    }
                }
                
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
