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

@available(iOS 14.0, *)
/// An button that displays the icon and name of an SSO provider.
struct AuthenticationSSOButton: View {
    
    // MARK: - Constants
    
    enum Brand: String {
        case apple, facebook, github, gitlab, google, twitter
    }
    
    // MARK: - Private
    
    @Environment(\.theme) private var theme
    
    // MARK: - Public
    
    let provider: SSOIdentityProvider
    let action: () -> Void
    
    // MARK: - Views
    
    var body: some View {
        Button(action: action) {
            HStack {
                icon
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(VectorL10n.socialLoginButtonTitleContinue(provider.name))
                    .foregroundColor(theme.colors.primaryContent)
                    .multilineTextAlignment(.center)
                    .layoutPriority(1)
                
                icon
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing)
                    .opacity(0)
            }
            .frame(maxWidth: .infinity)
            .contentShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(SecondaryActionButtonStyle(customColor: theme.colors.quinaryContent))
    }
    
    @ViewBuilder
    var icon: some View {
        switch provider.brand {
        case Brand.apple.rawValue:
            Image(Asset.Images.authenticationSsoIconApple.name)
                .renderingMode(.template)
                .foregroundColor(theme.colors.primaryContent)
        case Brand.facebook.rawValue:
            Image(Asset.Images.authenticationSsoIconFacebook.name)
        case Brand.github.rawValue:
            Image(Asset.Images.authenticationSsoIconGithub.name)
                .renderingMode(.template)
                .foregroundColor(theme.colors.primaryContent)
        case Brand.gitlab.rawValue:
            Image(Asset.Images.authenticationSsoIconGitlab.name)
        case Brand.google.rawValue:
            Image(Asset.Images.authenticationSsoIconGoogle.name)
        case Brand.twitter.rawValue:
            Image(Asset.Images.authenticationSsoIconTwitter.name)
        default:
            EmptyView()
        }
    }
}
