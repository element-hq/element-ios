/*
Copyright 2020-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import UIKit
import Reusable

final class SecureBackupSetupIntroCell: UIView, NibOwnerLoadable, Themable {
    
    // MARK: - Constants
    
    private enum ImageAlpha {
        static let highlighted: CGFloat = 0.3
    }
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var backgroundView: UIView!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var informationLabel: UILabel!
    @IBOutlet private weak var accessoryImageView: UIImageView!
    @IBOutlet private weak var separatorView: UIView!
    
    // MARK: Private
    
    private var theme: Theme?
    
    private var isHighlighted: Bool = false {
        didSet {
            self.updateView()
        }
    }
    
    // MARK: Public
    
    var action: (() -> Void)?
    
    // MARK: Setup
    
    private func commonInit() {
        self.setupGestureRecognizer()
        
        let accessoryTemplateImage = Asset.Images.disclosureIcon.image.withRenderingMode(.alwaysTemplate)
        self.accessoryImageView.image = accessoryTemplateImage
        self.accessoryImageView.highlightedImage = accessoryTemplateImage.vc_withAlpha(ImageAlpha.highlighted)
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.loadNibContent()
        self.commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.loadNibContent()
        self.commonInit()
    }
    
    // MARK: - Public
    
    func update(theme: Theme) {
        self.theme = theme
        
        self.backgroundView.backgroundColor = theme.backgroundColor
        self.imageView.tintColor = theme.textPrimaryColor
        self.titleLabel.textColor = theme.tintColor
        self.informationLabel.textColor = theme.textSecondaryColor
        self.accessoryImageView.tintColor = theme.textSecondaryColor
        self.separatorView.backgroundColor = theme.lineBreakColor
        
        self.updateView()
    }
    
    func fill(title: String, information: String, image: UIImage) {
        let templateImage = image.withRenderingMode(.alwaysTemplate)
        
        self.imageView.image = templateImage
        self.imageView.highlightedImage = templateImage.vc_withAlpha(ImageAlpha.highlighted)
        
        self.titleLabel.text = title
        self.informationLabel.text = information
        
        self.setupAccessibility(title: title, isEnabled: true)
        self.updateView()
    }
    
    // MARK: - Private
    
    private func setupAccessibility(title: String, isEnabled: Bool) {
        self.isAccessibilityElement = true
        self.accessibilityLabel = title
        self.accessibilityTraits = .button
        if !isEnabled {
            self.accessibilityTraits.insert(.notEnabled)
        }
    }
    
    private func setupGestureRecognizer() {
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(buttonAction(_:)))
        gestureRecognizer.minimumPressDuration = 0
        self.addGestureRecognizer(gestureRecognizer)
    }
    
    private func updateView() {
        
        if let theme = self.theme {
            self.backgroundView.backgroundColor = self.isHighlighted ? theme.overlayBackgroundColor : theme.backgroundColor
        }
        
        self.imageView.isHighlighted = self.isHighlighted
        self.accessoryImageView.isHighlighted = self.isHighlighted
    }
    
    // MARK: - Actions
    
    @objc private func buttonAction(_ sender: UILongPressGestureRecognizer) {
        
        let isBackgroundViewTouched = sender.vc_isTouchingInside()
        
        switch sender.state {
        case .began, .changed:
            self.isHighlighted = isBackgroundViewTouched
        case .ended:
            self.isHighlighted = false
            
            if isBackgroundViewTouched {
                self.action?()
            }
        case .cancelled:
            self.isHighlighted = false
        default:
            break
        }
    }
    
}
