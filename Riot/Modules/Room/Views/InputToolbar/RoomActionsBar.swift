// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit

@objcMembers
class RoomActionsBar: UIScrollView, Themable {
    // MARK: - Properties
    
    var itemSpacing: CGFloat = 20 {
        didSet {
            self.setNeedsLayout()
        }
    }
    
    var actionItems: [RoomActionItem] = [] {
        didSet {
            var actionButtons: [UIButton] = []
            for (index, item) in actionItems.enumerated() {
                let button = UIButton(type: .custom)
                button.setImage(item.image, for: .normal)
                button.addTarget(self, action: #selector(buttonAction(_:)), for: .touchUpInside)
                button.tintColor = ThemeService.shared().theme.tintColor
                button.tag = index
                actionButtons.append(button)
                addSubview(button)
            }
            self.actionButtons = actionButtons
            self.lastBounds = .zero
            self.setNeedsLayout()
        }
    }
    
    private var actionButtons: [UIButton] = [] {
        willSet {
            for button in actionButtons {
                button.removeFromSuperview()
            }
        }
    }
    
    private var lastBounds = CGRect.zero
    
    // MARK: - Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        guard lastBounds != self.bounds else {
            return
        }

        lastBounds = self.bounds

        var currentX: CGFloat = 0
        for button in actionButtons {
            button.transform = CGAffineTransform.identity
            button.frame = CGRect(x: currentX, y: 0, width: self.bounds.height, height: self.bounds.height)
            currentX = button.frame.maxX + itemSpacing
        }

        self.contentSize = CGSize(width: currentX - itemSpacing, height: self.bounds.height)
    }
    
    // MARK: - Themable
    
    func update(theme: Theme) {
        for button in actionButtons {
            button.tintColor = theme.tintColor
        }
    }
    
    // MARK: - Business methods
    
    func animate(showIn: Bool, completion: ((Bool) -> Void)? = nil) {
        if showIn {
            for button in actionButtons {
                button.transform = CGAffineTransform(translationX: 0, y: self.bounds.height)
            }
            for (index, button) in actionButtons.enumerated() {
                UIView.animate(withDuration: 0.3, delay: 0.05 * Double(index), usingSpringWithDamping: 0.45, initialSpringVelocity: 11, options: .curveEaseInOut) {
                    button.transform = CGAffineTransform.identity
                } completion: { (finished) in
                    completion?(finished)
                }
            }
        } else {
            for (index, button) in actionButtons.enumerated() {
                UIView.animate(withDuration: 0.25, delay: 0.05 * Double(index), options: .curveEaseInOut) {
                    button.transform = CGAffineTransform(translationX: 0, y: self.bounds.height)
                } completion: { (finished) in
                    if index == self.actionButtons.count - 1 {
                        completion?(finished)
                    }
                }
            }
        }
    }
    
    // MARK: - Private methods
    
    @objc private func buttonAction(_ sender: UIButton) {
        actionItems[sender.tag].action()
    }
    
    private func setupView() {
        self.showsHorizontalScrollIndicator = false
    }
}
