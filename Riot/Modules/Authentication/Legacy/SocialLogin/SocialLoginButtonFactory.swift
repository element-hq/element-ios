// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

@objc
enum SocialLoginButtonMode: Int {
    case `continue`
    case signIn
    case signUp
}

/// `SocialLoginButtonFactory` builds SocialLoginButton and apply dedicated theme if needed.
class SocialLoginButtonFactory {
    
    // MARK - Public
            
    func build(with identityProvider: MXLoginSSOIdentityProvider, mode: SocialLoginButtonMode) -> SocialLoginButton {
        let button = SocialLoginButton()
        
        let defaultStyle: SocialLoginButtonStyle
        var styles: [String: SocialLoginButtonStyle] = [:]
        
        let buildDefaultButtonStyles: () -> (SocialLoginButtonStyle, [String: SocialLoginButtonStyle]) = {
            let image: SourceImage?
            
            if let imageStringURL = identityProvider.icon, let imageURL = URL(string: imageStringURL) {
                image = .remote(imageURL)
            } else {
                image = nil
            }
            
            return self.buildDefaultButtonStyles(with: image)
        }
                                
        if let idpBrandIdentifier = identityProvider.brand {
            let idpBrand = MXLoginSSOIdentityProviderBrand(rawValue: idpBrandIdentifier)

            switch idpBrand {
            case .gitlab:
                (defaultStyle, styles) = self.buildGitLabButtonStyles()
            case .github:
                (defaultStyle, styles) = self.buildGitHubButtonStyles()
            case .apple:
                (defaultStyle, styles) = self.buildAppleButtonStyles()
            case .google:
                (defaultStyle, styles) = self.buildGoogleButtonStyles()
            case .facebook:
                (defaultStyle, styles) = self.buildFacebookButtonStyles()
            case .twitter:
                (defaultStyle, styles) = self.buildTwitterButtonStyles()
            default:
                (defaultStyle, styles) = buildDefaultButtonStyles()
            }
        } else {
            (defaultStyle, styles) = buildDefaultButtonStyles()
        }
        
        let title = self.buildButtonTitle(with: identityProvider.name, mode: mode)
        
        let viewData = SocialLoginButtonViewData(identityProvider: identityProvider.ssoIdentityProvider,
                                                 title: title,
                                                 defaultStyle: defaultStyle,
                                                 themeStyles: styles)
        
        button.fill(with: viewData)
        
        return button
    }
    
    // MARK - Private
    
    private func buildButtonTitle(with providerTitle: String, mode: SocialLoginButtonMode) -> String {
        let buttonTitle: String
        
        switch mode {
        case .signIn:
            buttonTitle = VectorL10n.socialLoginButtonTitleSignIn(providerTitle)
        case .signUp:
            buttonTitle = VectorL10n.socialLoginButtonTitleSignUp(providerTitle)
        case .continue:
            buttonTitle = VectorL10n.socialLoginButtonTitleContinue(providerTitle)
        }
        
        return buttonTitle
    }
    
    private func buildAppleButtonStyles() -> (SocialLoginButtonStyle, [String: SocialLoginButtonStyle]) {
        
        var lightImage: SourceImage?
        
        let appleLogo = Asset.Images.socialLoginButtonApple.image
        
        if let appleLogoLightStyle = appleLogo.vc_tintedImage(usingColor: .white) {
            lightImage = .local(appleLogoLightStyle)
        }
        
        let lightStyle = SocialLoginButtonStyle(logo: lightImage,
                                                titleColor: .white,
                                                backgroundColor: .black,
                                                borderColor: nil)
        
        var darkImage: SourceImage?
        
        if let appleLogoDarkStyle = appleLogo.vc_tintedImage(usingColor: .black) {
            darkImage = .local(appleLogoDarkStyle)
        }
        
        let darkStyle = SocialLoginButtonStyle(logo: darkImage,
                                               titleColor: .black,
                                               backgroundColor: .white,
                                               borderColor: nil)
        
        let defaultStyle: SocialLoginButtonStyle = lightStyle
                        
        let styles: [String: SocialLoginButtonStyle] = [
            ThemeIdentifier.light.rawValue: lightStyle,
            ThemeIdentifier.dark.rawValue: darkStyle,
            ThemeIdentifier.black.rawValue: darkStyle
        ]
        
        return (defaultStyle, styles)
    }
    
    private func buildGoogleButtonStyles() -> (SocialLoginButtonStyle, [String: SocialLoginButtonStyle]) {
        
        let logo = Asset.Images.socialLoginButtonGoogle.image
        
        let lightImage: SourceImage = .local(logo)
        
        let lightStyle = SocialLoginButtonStyle(logo: lightImage,
                                                titleColor: UIColor(white: 0, alpha: 0.54),
                                                backgroundColor: .white,
                                                borderColor: .black)
        
        var darkImage: SourceImage?
        
        if let logoDarkStyle = logo.vc_tintedImage(usingColor: .white) {
            darkImage = .local(logoDarkStyle)
        }
        
        let darkStyle = SocialLoginButtonStyle(logo: darkImage,
                                               titleColor: .white,
                                               backgroundColor: UIColor(rgb: 0x4285F4),
                                               borderColor: nil)
        
        let defaultStyle: SocialLoginButtonStyle = lightStyle
        
        let styles: [String: SocialLoginButtonStyle] = [
            ThemeIdentifier.light.rawValue: lightStyle,
            ThemeIdentifier.dark.rawValue: darkStyle,
            ThemeIdentifier.black.rawValue: darkStyle
        ]
        
        return (defaultStyle, styles)
    }
    
    private func buildTwitterButtonStyles() -> (SocialLoginButtonStyle, [String: SocialLoginButtonStyle]) {
        
        let defaultStyle = SocialLoginButtonStyle(logo: .local(Asset.Images.socialLoginButtonTwitter.image),
                                                  titleColor: .white,
                                                  backgroundColor: UIColor(rgb: 0x47ACDF),
                                                  borderColor: nil)
        return (defaultStyle, [:])
    }
    
    private func buildFacebookButtonStyles() -> (SocialLoginButtonStyle, [String: SocialLoginButtonStyle]) {
        
        let defaultStyle = SocialLoginButtonStyle(logo: .local(Asset.Images.socialLoginButtonFacebook.image),
                                                  titleColor: .white,
                                                  backgroundColor: UIColor(rgb: 0x3C5A99),
                                                  borderColor: nil)
        return (defaultStyle, [:])
    }
    
    private func buildGitHubButtonStyles() -> (SocialLoginButtonStyle, [String: SocialLoginButtonStyle]) {
        
        var lightImage: SourceImage?
        
        let githubLogo = Asset.Images.socialLoginButtonGithub.image
        
        if let githubLogoLightStyle = githubLogo.vc_tintedImage(usingColor: .black) {
            lightImage = .local(githubLogoLightStyle)
        }
        
        let lightStyle = SocialLoginButtonStyle(logo: lightImage,
                                                titleColor: .black,
                                                backgroundColor: .white,
                                                borderColor: .black)
        
        var darkImage: SourceImage?
        
        if let githubLogoDarkStyle = githubLogo.vc_tintedImage(usingColor: .white) {
            darkImage = .local(githubLogoDarkStyle)
        }
        
        let darkStyle = SocialLoginButtonStyle(logo: darkImage,
                                               titleColor: .white,
                                               backgroundColor: .black,
                                               borderColor: .white)
        
        let defaultStyle: SocialLoginButtonStyle = lightStyle
        
        let styles: [String: SocialLoginButtonStyle] = [
            ThemeIdentifier.light.rawValue: lightStyle,
            ThemeIdentifier.dark.rawValue: darkStyle,
            ThemeIdentifier.black.rawValue: darkStyle
        ]
        
        return (defaultStyle, styles)
    }
    
    private func buildGitLabButtonStyles() -> (SocialLoginButtonStyle, [String: SocialLoginButtonStyle]) {
                
        let logo: SourceImage = .local(Asset.Images.socialLoginButtonGitlab.image)
        
        let lightStyle = SocialLoginButtonStyle(logo: logo,
                                                titleColor: .black,
                                                backgroundColor: .white,
                                                borderColor: .black)
        
        let darkStyle = SocialLoginButtonStyle(logo: logo,
                                               titleColor: .white,
                                               backgroundColor: .black,
                                               borderColor: .white)
        
        let defaultStyle: SocialLoginButtonStyle = lightStyle
        
        let styles: [String: SocialLoginButtonStyle] = [
            ThemeIdentifier.light.rawValue: lightStyle,
            ThemeIdentifier.dark.rawValue: darkStyle,
            ThemeIdentifier.black.rawValue: darkStyle
        ]
        
        return (defaultStyle, styles)
    }
    
    private func buildDefaultButtonStyles(with image: SourceImage?) -> (SocialLoginButtonStyle, [String: SocialLoginButtonStyle]) {
        
        let lightStyle = SocialLoginButtonStyle(logo: image,
                                                titleColor: .black,
                                                backgroundColor: .white,
                                                borderColor: .black)
        
        let darkStyle = SocialLoginButtonStyle(logo: image,
                                               titleColor: .white,
                                               backgroundColor: .black,
                                               borderColor: .white)
        
        let defaultStyle: SocialLoginButtonStyle = lightStyle
        
        let styles: [String: SocialLoginButtonStyle] = [
            ThemeIdentifier.light.rawValue: lightStyle,
            ThemeIdentifier.dark.rawValue: darkStyle,
            ThemeIdentifier.black.rawValue: darkStyle
        ]
        
        return (defaultStyle, styles)
    }
}
