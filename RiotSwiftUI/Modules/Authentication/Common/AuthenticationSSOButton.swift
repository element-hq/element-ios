//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// A button that displays the icon and name of an SSO provider.
struct AuthenticationSSOButton: View {
    // MARK: - Constants
    
    enum Brand: String {
        case apple, facebook, github, gitlab, google, twitter
    }
    
    // MARK: - Private
    
    @Environment(\.theme) private var theme
    @ScaledMetric private var iconSize = 24
    
    private var renderingMode: Image.TemplateRenderingMode? {
        provider.brand == Brand.apple.rawValue || provider.brand == Brand.github.rawValue ? .template : nil
    }
    
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
            .fixedSize(horizontal: false, vertical: true)
            .contentShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(SecondaryActionButtonStyle(customColor: theme.colors.quinaryContent))
    }
    
    /// The icon with appropriate rendering mode and size for dynamic type.
    var icon: some View {
        iconImage.map { image in
            image
                .renderingMode(renderingMode)
                .resizable()
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
                .foregroundColor(renderingMode == .template ? theme.colors.primaryContent : nil)
        }
    }
    
    /// The image to be shown in the icon.
    var iconImage: Image? {
        switch provider.brand {
        case Brand.apple.rawValue:
            return Image(Asset.Images.authenticationSsoIconApple.name)
        case Brand.facebook.rawValue:
            return Image(Asset.Images.authenticationSsoIconFacebook.name)
        case Brand.github.rawValue:
            return Image(Asset.Images.authenticationSsoIconGithub.name)
        case Brand.gitlab.rawValue:
            return Image(Asset.Images.authenticationSsoIconGitlab.name)
        case Brand.google.rawValue:
            return Image(Asset.Images.authenticationSsoIconGoogle.name)
        case Brand.twitter.rawValue:
            return Image(Asset.Images.authenticationSsoIconTwitter.name)
        default:
            return nil
        }
    }
}

struct AuthenticationSSOButton_Previews: PreviewProvider {
    static var matrixDotOrg = AuthenticationHomeserverViewData.mockMatrixDotOrg
    
    static var buttons: some View {
        VStack {
            ForEach(matrixDotOrg.ssoIdentityProviders) { provider in
                AuthenticationSSOButton(provider: provider) { }
            }
            AuthenticationSSOButton(provider: SSOIdentityProvider(id: "", name: "SAML", brand: nil, iconURL: nil)) { }
        }
        .padding()
    }
    
    static var previews: some View {
        buttons
            .theme(.light).preferredColorScheme(.light)
            .environment(\.sizeCategory, .accessibilityLarge)
        buttons
            .theme(.dark).preferredColorScheme(.dark)
    }
}
