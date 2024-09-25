/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import UIKit
import Reusable

final class ContextualMenuItemView: UIView, NibOwnerLoadable {
    
    // MARK: - Constants
    
    private enum ColorAlpha {
        static let normal: CGFloat = 1.0
        static let highlighted: CGFloat = 0.3
    }
    
    private enum ViewAlpha {
        static let normal: CGFloat = 1.0
        static let disabled: CGFloat = 0.3
    }
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    
    // MARK: Private
    
    private var originalImage: UIImage?
    
    private var isHighlighted: Bool = false {
        didSet {
            self.updateView()
        }
    }
    
    // MARK: Public
    
    var titleColor: UIColor = .black {
        didSet {
            self.updateView()
        }
    }
    
    var imageColor: UIColor = .black {
        didSet {
            self.updateView()
        }
    }
    
    var isEnabled: Bool = true {
        didSet {
            self.updateView()
        }
    }
    
    var action: (() -> Void)?
    
    // MARK: Setup
    
    private func commonInit() {
        self.setupGestureRecognizer()
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
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

    func fill(menuItem: RoomContextualMenuItem) {
        self.fill(title: menuItem.title, image: menuItem.image)
        self.setupAccessibility(title: menuItem.title, isEnabled: menuItem.isEnabled)
        self.action = menuItem.action
        self.isEnabled = menuItem.isEnabled
    }
    
    // MARK: - Private

    private func fill(title: String, image: UIImage?) {
        self.originalImage = image?.withRenderingMode(.alwaysTemplate)
        self.titleLabel.text = title
        self.updateView()
    }

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
        
        let viewAlpha = self.isEnabled ? ViewAlpha.normal : ViewAlpha.disabled
        let colorAlpha = self.isHighlighted ? ColorAlpha.highlighted : ColorAlpha.normal
        
        self.updateTitleAndImageAlpha(viewAlpha)
        self.imageView.tintColor = self.imageColor
        self.updateTitleAndImageColorAlpha(colorAlpha)
    }
    
    private func updateTitleAndImageAlpha(_ alpha: CGFloat) {
        self.imageView.alpha = alpha
        self.titleLabel.alpha = alpha
    }
    
    private func updateTitleAndImageColorAlpha(_ alpha: CGFloat) {
        let titleColor: UIColor
        let image: UIImage?
        
        if alpha < 1.0 {
            titleColor = self.titleColor.withAlphaComponent(alpha)
            image = self.originalImage?.vc_tintedImage(usingColor: self.imageColor.withAlphaComponent(alpha))
        } else {
            titleColor = self.titleColor
            image = self.originalImage
        }
        
        self.titleLabel.textColor = titleColor
        self.imageView.image = image
    }
    
    // MARK: - Actions
    
    @objc private func buttonAction(_ sender: UILongPressGestureRecognizer) {
        guard self.isEnabled else {
            return
        }
        
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
