/*
 Copyright 2019 New Vector Ltd
 
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
    
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var titleLabel: UILabel!
    
    // MARK: Private
    
    private var originalImage: UIImage?
    
    private var isHighlighted = false {
        didSet {
            updateView()
        }
    }
    
    // MARK: Public
    
    var titleColor: UIColor = .black {
        didSet {
            updateView()
        }
    }
    
    var imageColor: UIColor = .black {
        didSet {
            updateView()
        }
    }
    
    var isEnabled = true {
        didSet {
            updateView()
        }
    }
    
    var action: (() -> Void)?
    
    // MARK: Setup
    
    private func commonInit() {
        setupGestureRecognizer()
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
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

    func fill(menuItem: RoomContextualMenuItem) {
        fill(title: menuItem.title, image: menuItem.image)
        setupAccessibility(title: menuItem.title, isEnabled: menuItem.isEnabled)
        action = menuItem.action
        isEnabled = menuItem.isEnabled
    }
    
    // MARK: - Private

    private func fill(title: String, image: UIImage?) {
        originalImage = image?.withRenderingMode(.alwaysTemplate)
        titleLabel.text = title
        updateView()
    }

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
        let viewAlpha = isEnabled ? ViewAlpha.normal : ViewAlpha.disabled
        let colorAlpha = isHighlighted ? ColorAlpha.highlighted : ColorAlpha.normal
        
        updateTitleAndImageAlpha(viewAlpha)
        imageView.tintColor = imageColor
        updateTitleAndImageColorAlpha(colorAlpha)
    }
    
    private func updateTitleAndImageAlpha(_ alpha: CGFloat) {
        imageView.alpha = alpha
        titleLabel.alpha = alpha
    }
    
    private func updateTitleAndImageColorAlpha(_ alpha: CGFloat) {
        let titleColor: UIColor
        let image: UIImage?
        
        if alpha < 1.0 {
            titleColor = self.titleColor.withAlphaComponent(alpha)
            image = originalImage?.vc_tintedImage(usingColor: imageColor.withAlphaComponent(alpha))
        } else {
            titleColor = self.titleColor
            image = originalImage
        }
        
        titleLabel.textColor = titleColor
        imageView.image = image
    }
    
    // MARK: - Actions
    
    @objc private func buttonAction(_ sender: UILongPressGestureRecognizer) {
        guard isEnabled else {
            return
        }
        
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
