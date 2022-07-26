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

import UIKit
import AFNetworking

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
        self.commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.commonInit()
    }
    
    private func commonInit() {
        self.clipsToBounds = true
        self.layer.masksToBounds = true
        self.layer.cornerRadius = Constants.cornerRadius
        self.titleLabel?.font = UIFont.systemFont(ofSize: Constants.fontSize)
        self.imageEdgeInsets.right = Constants.imageEdgeInsetRight
        self.update(theme: ThemeService.shared().theme)
    }
    
    // MARK: - Public
    
    func fill(with viewData: SocialLoginButtonViewData) {
        self.viewData = viewData
        
        self.setTitle(viewData.title, for: .normal)
        
        self.updateWithCurrentTheme()
    }
    
    // MARK: - Private
    
    private func updateButtonStyle(with theme: Theme) {
        guard let viewData = self.viewData else {
            return
        }
        
        let buttonStyle: SocialLoginButtonStyle
        
        if let themeStyle = viewData.themeStyles[theme.identifier] {
            buttonStyle = themeStyle
        } else {
            buttonStyle = viewData.defaultStyle
        }
        
        self.update(with: buttonStyle)
    }
    
    private func update(with buttonStyle: SocialLoginButtonStyle) {
        
        // Image
        if let sourceImage = buttonStyle.logo {
            switch sourceImage {
            case .local(let image):
                self.setImage(image, for: .normal)
            case .remote(let imageURL):
                let urlRequest = URLRequest(url: imageURL)
                self.setImageFor(.normal, with: urlRequest, placeholderImage: nil) { (urlRequest, httpURLResponse, image) in
                    let resizedImage = image.vc_resized(with: Constants.imageTargetSize)
                    self.setImage(resizedImage, for: .normal)
                } failure: { (urlRequest, httpURLResponse, error) in
                    self.setImage(nil, for: .normal)
                }
            }
        } else {
            self.setImage(nil, for: .normal)
        }
        
        // Background
        
        self.vc_setBackgroundColor(buttonStyle.backgroundColor, for: .normal)
        
        self.layer.borderWidth = buttonStyle.borderColor != nil ? Constants.borderWidth : 0.0
        self.layer.borderColor = buttonStyle.borderColor?.cgColor
        
        // Title
        
        self.setTitleColor(buttonStyle.titleColor, for: .normal)
        self.setTitleColor(buttonStyle.titleColor.withAlphaComponent(Constants.highlightedAlpha), for: .highlighted)
    }
    
    private func updateWithCurrentTheme() {
        guard let theme = self.theme else {
            return
        }
        self.update(theme: theme)
    }
    
    // MARK: - Themable
    
    func update(theme: Theme) {
        self.theme = theme
        self.updateButtonStyle(with: theme)
    }
}
