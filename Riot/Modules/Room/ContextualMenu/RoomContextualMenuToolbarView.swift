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

final class RoomContextualMenuToolbarView: MXKRoomInputToolbarView, NibOwnerLoadable, Themable {
    // MARK: - Constants
    
    private enum Constants {
        static let menuItemMinWidth: CGFloat = 50.0
        static let menuItemMaxWidth: CGFloat = 80.0
    }
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private var menuItemsStackView: UIStackView!
    @IBOutlet private var separatorView: UIView!
    
    // MARK: Private
    
    private var theme: Theme?
    private var menuItemViews: [ContextualMenuItemView] = []
    
    // MARK: - Public
    
    @objc func update(theme: Theme) {
        self.theme = theme
        backgroundColor = theme.backgroundColor
        tintColor = theme.tintColor
        
        for menuItemView in menuItemViews {
            menuItemView.titleColor = theme.tintColor
            menuItemView.imageColor = theme.tintColor
        }
    }
    
    @objc func fill(contextualMenuItems: [RoomContextualMenuItem]) {
        menuItemsStackView.vc_removeAllArrangedSubviews()
        menuItemViews.removeAll()
        
        for menuItem in contextualMenuItems {
            let menuItemView = ContextualMenuItemView()
            menuItemView.fill(menuItem: menuItem)
            
            if let theme = theme {
                menuItemView.titleColor = theme.textPrimaryColor
                menuItemView.imageColor = theme.tintColor
            }
            
            add(menuItemView: menuItemView)
        }
        
        layoutIfNeeded()
    }
    
    // MARK: - Setup
    
    private func commonInit() {
        separatorView.isHidden = true
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
        loadNibContent()
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
    
    // MARK: - Life cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    // MARK: - Private
    
    private func add(menuItemView: ContextualMenuItemView) {
        let menuItemContentView = UIView()
        menuItemContentView.backgroundColor = .clear
        
        add(menuItemView: menuItemView, on: menuItemContentView)
        
        menuItemsStackView.addArrangedSubview(menuItemContentView)
        
        let widthConstraint = menuItemContentView.widthAnchor.constraint(equalTo: menuItemsStackView.widthAnchor)
        widthConstraint.priority = .defaultLow
        widthConstraint.isActive = true
        
        menuItemViews.append(menuItemView)
    }
    
    private func add(menuItemView: ContextualMenuItemView, on contentView: UIView) {
        contentView.translatesAutoresizingMaskIntoConstraints = false
        menuItemView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(menuItemView)
        
        menuItemView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        menuItemView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        
        let widthConstraint = menuItemView.widthAnchor.constraint(equalToConstant: 0.0)
        widthConstraint.priority = .defaultLow
        widthConstraint.isActive = true
        
        let minWidthConstraint = menuItemView.widthAnchor.constraint(greaterThanOrEqualToConstant: Constants.menuItemMinWidth)
        minWidthConstraint.priority = .required
        minWidthConstraint.isActive = true
        
        let maxWidthConstraint = menuItemView.widthAnchor.constraint(lessThanOrEqualToConstant: Constants.menuItemMaxWidth)
        maxWidthConstraint.priority = .required
        maxWidthConstraint.isActive = true
    }
}
