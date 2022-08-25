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

import UIKit

@objcMembers
class RoomActionsBar: UIScrollView, Themable {
    // MARK: - Properties
    
    var itemSpacing: CGFloat = 20 {
        didSet {
            setNeedsLayout()
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
            lastBounds = .zero
            setNeedsLayout()
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

        guard lastBounds != bounds else {
            return
        }

        lastBounds = bounds

        var currentX: CGFloat = 0
        for button in actionButtons {
            button.transform = CGAffineTransform.identity
            button.frame = CGRect(x: currentX, y: 0, width: bounds.height, height: bounds.height)
            currentX = button.frame.maxX + itemSpacing
        }

        contentSize = CGSize(width: currentX - itemSpacing, height: bounds.height)
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
                button.transform = CGAffineTransform(translationX: 0, y: bounds.height)
            }
            for (index, button) in actionButtons.enumerated() {
                UIView.animate(withDuration: 0.3, delay: 0.05 * Double(index), usingSpringWithDamping: 0.45, initialSpringVelocity: 11, options: .curveEaseInOut) {
                    button.transform = CGAffineTransform.identity
                } completion: { finished in
                    completion?(finished)
                }
            }
        } else {
            for (index, button) in actionButtons.enumerated() {
                UIView.animate(withDuration: 0.25, delay: 0.05 * Double(index), options: .curveEaseInOut) {
                    button.transform = CGAffineTransform(translationX: 0, y: self.bounds.height)
                } completion: { finished in
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
        showsHorizontalScrollIndicator = false
    }
}
