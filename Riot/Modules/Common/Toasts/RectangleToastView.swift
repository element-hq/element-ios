// 
// Copyright 2021 New Vector Ltd
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

import Foundation
import UIKit

class RectangleToastView: UIView, Themable {
    
    private enum Constants {
        static let padding: UIEdgeInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        static let cornerRadius: CGFloat = 8.0
    }
    
    private lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()
    
    private lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.font = ThemeService.shared().theme.fonts.body
        label.backgroundColor = .clear
        label.numberOfLines = 0
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var stackView: UIStackView = {
        let result = UIStackView()
        result.axis = .horizontal
        result.distribution = .fill
        result.alignment = .center
        result.spacing = 8.0
        result.backgroundColor = .clear
        
        addSubview(result)
        result.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            result.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.padding.left),
            result.topAnchor.constraint(equalTo: topAnchor, constant: Constants.padding.top),
            result.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constants.padding.right),
            result.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Constants.padding.bottom)
        ])
        
        return result
    }()
    
    init(withMessage message: String?,
         image: UIImage? = nil) {
        super.init(frame: .zero)
        
        if let image = image {
            imageView.image = image
            NSLayoutConstraint.activate([
                imageView.widthAnchor.constraint(equalToConstant: image.size.width),
                imageView.heightAnchor.constraint(equalToConstant: image.size.height)
            ])
            stackView.addArrangedSubview(imageView)
        }
        
        messageLabel.text = message
        stackView.addArrangedSubview(messageLabel)
        
        stackView.layoutIfNeeded()
        layer.cornerRadius = Constants.cornerRadius
        layer.masksToBounds = true
        registerThemeServiceDidChangeThemeNotification()
        themeDidChange()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(themeDidChange),
                                               name: .themeServiceDidChangeTheme,
                                               object: nil)
    }
    
    @objc
    private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
    
    //  MARK: Themable
    
    func update(theme: Theme) {
        backgroundColor = theme.colors.quinaryContent
        imageView.tintColor = theme.colors.tertiaryContent
        messageLabel.textColor = theme.colors.primaryContent
        messageLabel.font = theme.fonts.body
    }
    
}
