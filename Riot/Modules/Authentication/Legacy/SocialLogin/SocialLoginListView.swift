// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit
import Reusable

@objc protocol SocialLoginListViewDelegate: AnyObject {
    func socialLoginListView(_ socialLoginListView: SocialLoginListView, didTapSocialButtonWithProvider identityProvider: SSOIdentityProvider)
}

/// SocialLoginListView displays a list of social login buttons according to a given array of SSO Identity Providers.
@objcMembers
final class SocialLoginListView: UIView, NibLoadable {
    
    // MARK: - Constants
    
    private static let sizingView = SocialLoginListView.instantiate()
    
    private enum Constants {
        static let buttonHeight: CGFloat = 44.0
    }
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var buttonsStackView: UIStackView!
    
    // MARK: Private
    
    private let socialButtonFactory: SocialLoginButtonFactory = SocialLoginButtonFactory()
    private var theme: Theme!
    private var buttons: [SocialLoginButton] = []
    private(set) var mode: SocialLoginButtonMode = .continue
    
    // MARK: Public
    
    weak var delegate: SocialLoginListViewDelegate?
    
    // MARK: - Setup
    
    static func instantiate() -> SocialLoginListView {
        let view = SocialLoginListView.loadFromNib()
        view.theme = ThemeService.shared().theme        
        return view
    }
    
    // MARK: - Public            
    
    func update(with identityProviders: [MXLoginSSOIdentityProvider], mode: SocialLoginButtonMode) {
        self.mode = mode
        
        let title: String
        
        switch mode {
        case .continue:
            title = VectorL10n.socialLoginListTitleContinue
        case .signIn:
            title = VectorL10n.socialLoginListTitleSignIn
        case .signUp:
            title = VectorL10n.socialLoginListTitleSignUp
        }
        
        self.titleLabel.text = title
        
        self.removeButtons()
        let buttons = self.socialLoginButtons(for: identityProviders, mode: mode)
        
        for button in buttons {
            button.translatesAutoresizingMaskIntoConstraints = false
            button.heightAnchor.constraint(equalToConstant: Constants.buttonHeight).isActive = true
            self.buttonsStackView.addArrangedSubview(button)
        }
        
        self.buttons = buttons
    }
        
    static func contentViewHeight(identityProviders: [MXLoginSSOIdentityProvider],
                                  mode: SocialLoginButtonMode,
                                  fitting width: CGFloat) -> CGFloat {
        let sizingView = self.sizingView
        
        sizingView.frame = CGRect(x: 0, y: 0, width: width, height: 1)
        
        sizingView.update(with: identityProviders, mode: mode)
        
        sizingView.setNeedsLayout()
        sizingView.layoutIfNeeded()
        
        let fittingSize = CGSize(width: width, height: UIView.layoutFittingCompressedSize.height)
        
        return sizingView.systemLayoutSizeFitting(fittingSize).height
    }
    
    // MARK: - Private
    
    private func removeButtons() {
        self.buttonsStackView.vc_removeAllSubviews()
        self.buttons = []
    }
        
    private func socialLoginButtons(for identityProviders: [MXLoginSSOIdentityProvider], mode: SocialLoginButtonMode) -> [SocialLoginButton] {
        
        var buttons: [SocialLoginButton] = []
        
        // Order alphabeticaly by Identity Provider identifier
        let sortedIdentityProviders = identityProviders.sorted { (firstIdentityProvider, secondIdentityProvider) -> Bool in
            if let firstIdentityProviderBrand = firstIdentityProvider.brand, let secondIdentityProviderBrand = secondIdentityProvider.brand {
                return firstIdentityProviderBrand < secondIdentityProviderBrand
            } else {
                return firstIdentityProvider.identifier < secondIdentityProvider.identifier
            }
        }
        
        for identityProvider in sortedIdentityProviders {
            let socialLoginButton = self.socialButtonFactory.build(with: identityProvider, mode: mode)
            socialLoginButton.update(theme: self.theme)
            socialLoginButton.addTarget(self, action: #selector(socialButtonAction(_:)), for: .touchUpInside)
            buttons.append(socialLoginButton)
        }
         
        return buttons
    }
    
    // MARK: - Action
    
    @objc private func socialButtonAction(_ socialLoginButton: SocialLoginButton) {
        guard let provider = socialLoginButton.identityProvider else {
            return
        }
        self.delegate?.socialLoginListView(self, didTapSocialButtonWithProvider: provider)
    }
}

// MARK: - Themable
extension SocialLoginListView: Themable {
    func update(theme: Theme) {
        self.theme = theme
        
        self.titleLabel.textColor = theme.textSecondaryColor
        
        for button in self.buttons {
            button.update(theme: theme)
        }
    }
}
