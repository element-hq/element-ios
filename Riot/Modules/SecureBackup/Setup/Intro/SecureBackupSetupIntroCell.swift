/*
 Copyright 2020 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import Reusable
import UIKit

final class SecureBackupSetupIntroCell: UIView, NibOwnerLoadable, Themable {
    // MARK: - Constants
    
    private enum ImageAlpha {
        static let highlighted: CGFloat = 0.3
    }
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private var backgroundView: UIView!
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var informationLabel: UILabel!
    @IBOutlet private var accessoryImageView: UIImageView!
    @IBOutlet private var separatorView: UIView!
    
    // MARK: Private
    
    private var theme: Theme?
    
    private var isHighlighted = false {
        didSet {
            updateView()
        }
    }
    
    // MARK: Public
    
    var action: (() -> Void)?
    
    // MARK: Setup
    
    private func commonInit() {
        setupGestureRecognizer()
        
        let accessoryTemplateImage = Asset.Images.disclosureIcon.image.withRenderingMode(.alwaysTemplate)
        accessoryImageView.image = accessoryTemplateImage
        accessoryImageView.highlightedImage = accessoryTemplateImage.vc_withAlpha(ImageAlpha.highlighted)
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadNibContent()
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadNibContent()
        commonInit()
    }
    
    // MARK: - Public
    
    func update(theme: Theme) {
        self.theme = theme
        
        backgroundView.backgroundColor = theme.backgroundColor
        imageView.tintColor = theme.textPrimaryColor
        titleLabel.textColor = theme.tintColor
        informationLabel.textColor = theme.textSecondaryColor
        accessoryImageView.tintColor = theme.textSecondaryColor
        separatorView.backgroundColor = theme.lineBreakColor
        
        updateView()
    }
    
    func fill(title: String, information: String, image: UIImage) {
        let templateImage = image.withRenderingMode(.alwaysTemplate)
        
        imageView.image = templateImage
        imageView.highlightedImage = templateImage.vc_withAlpha(ImageAlpha.highlighted)
        
        titleLabel.text = title
        informationLabel.text = information
        
        setupAccessibility(title: title, isEnabled: true)
        updateView()
    }
    
    // MARK: - Private
    
    private func setupAccessibility(title: String, isEnabled: Bool) {
        isAccessibilityElement = true
        accessibilityLabel = title
        accessibilityTraits = .button
        if !isEnabled {
            accessibilityTraits.insert(.notEnabled)
        }
    }
    
    private func setupGestureRecognizer() {
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(buttonAction(_:)))
        gestureRecognizer.minimumPressDuration = 0
        addGestureRecognizer(gestureRecognizer)
    }
    
    private func updateView() {
        if let theme = theme {
            backgroundView.backgroundColor = isHighlighted ? theme.overlayBackgroundColor : theme.backgroundColor
        }
        
        imageView.isHighlighted = isHighlighted
        accessoryImageView.isHighlighted = isHighlighted
    }
    
    // MARK: - Actions
    
    @objc private func buttonAction(_ sender: UILongPressGestureRecognizer) {
        let isBackgroundViewTouched = sender.vc_isTouchingInside()
        
        switch sender.state {
        case .began, .changed:
            isHighlighted = isBackgroundViewTouched
        case .ended:
            isHighlighted = false
            
            if isBackgroundViewTouched {
                action?()
            }
        case .cancelled:
            isHighlighted = false
        default:
            break
        }
    }
}
