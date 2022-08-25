//
// Copyright 2020 New Vector Ltd
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

import AFNetworking
import UIKit

/// SocialLoginButton represents a button associated to a social login provider.
final class SocialLoginButton: UIButton, Themable {
    // MARK: - Constants
    
    private enum Constants {
        static let backgroundColorAlpha: CGFloat = 0.2
        static let cornerRadius: CGFloat = 8.0
        static let fontSize: CGFloat = 17.0
        static let borderWidth: CGFloat = 1.0
        static let imageEdgeInsetRight: CGFloat = 20.0
        static let imageTargetSize = CGSize(width: 24, height: 24)
        static let highlightedAlpha: CGFloat = 0.5
    }
    
    // MARK: - Properties
    
    // MARK: Private
    
    private var theme: Theme?
    private var viewData: SocialLoginButtonViewData?
    
    // MARK: Public
    
    var identifier: String? {
        viewData?.identityProvider.id
    }

    var identityProvider: SSOIdentityProvider? {
        viewData?.identityProvider
    }
    
    // MARK: Setup
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        clipsToBounds = true
        layer.masksToBounds = true
        layer.cornerRadius = Constants.cornerRadius
        titleLabel?.font = UIFont.systemFont(ofSize: Constants.fontSize)
        imageEdgeInsets.right = Constants.imageEdgeInsetRight
        update(theme: ThemeService.shared().theme)
    }
    
    // MARK: - Public
    
    func fill(with viewData: SocialLoginButtonViewData) {
        self.viewData = viewData
        
        setTitle(viewData.title, for: .normal)
        
        updateWithCurrentTheme()
    }
    
    // MARK: - Private
    
    private func updateButtonStyle(with theme: Theme) {
        guard let viewData = viewData else {
            return
        }
        
        let buttonStyle: SocialLoginButtonStyle
        
        if let themeStyle = viewData.themeStyles[theme.identifier] {
            buttonStyle = themeStyle
        } else {
            buttonStyle = viewData.defaultStyle
        }
        
        update(with: buttonStyle)
    }
    
    private func update(with buttonStyle: SocialLoginButtonStyle) {
        // Image
        if let sourceImage = buttonStyle.logo {
            switch sourceImage {
            case .local(let image):
                setImage(image, for: .normal)
            case .remote(let imageURL):
                let urlRequest = URLRequest(url: imageURL)
                setImageFor(.normal, with: urlRequest, placeholderImage: nil) { _, _, image in
                    let resizedImage = image.vc_resized(with: Constants.imageTargetSize)
                    self.setImage(resizedImage, for: .normal)
                } failure: { _, _, _ in
                    self.setImage(nil, for: .normal)
                }
            }
        } else {
            setImage(nil, for: .normal)
        }
        
        // Background
        
        vc_setBackgroundColor(buttonStyle.backgroundColor, for: .normal)
        
        layer.borderWidth = buttonStyle.borderColor != nil ? Constants.borderWidth : 0.0
        layer.borderColor = buttonStyle.borderColor?.cgColor
        
        // Title
        
        setTitleColor(buttonStyle.titleColor, for: .normal)
        setTitleColor(buttonStyle.titleColor.withAlphaComponent(Constants.highlightedAlpha), for: .highlighted)
    }
    
    private func updateWithCurrentTheme() {
        guard let theme = theme else {
            return
        }
        update(theme: theme)
    }
    
    // MARK: - Themable
    
    func update(theme: Theme) {
        self.theme = theme
        updateButtonStyle(with: theme)
    }
}
