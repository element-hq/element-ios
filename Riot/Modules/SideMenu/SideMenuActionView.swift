// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit
import Reusable

protocol SideMenuActionViewDelegate: AnyObject {
    func sideMenuActionView(_ actionView: SideMenuActionView, didTapMenuItem sideMenuItem: SideMenuItem?)
}

/// SideMenuActionView represents a side menu action view
final class SideMenuActionView: UIView, NibOwnerLoadable {
    
    private enum Constants {
        static let highlightedAlpha: CGFloat = 0.5
    }
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var button: UIButton!
    
    // MARK: Private
    
    private var theme: Theme!
    private var sideMenuItem: SideMenuItem?
    
    // MARK: Public
    
    weak var delegate: SideMenuActionViewDelegate?
    
    // MARK: - Setup
    
    class func instantiate() -> SideMenuActionView {
        let view = SideMenuActionView()
        view.theme = ThemeService.shared().theme
        return view
    }
    
    private func commonInit() {
        self.button.contentHorizontalAlignment = .left
        self.button.titleLabel?.lineBreakMode = .byTruncatingTail
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
    
    func fill(with image: UIImage, title: String) {
        self.button.setTitle(title, for: .normal)
        self.button.setImage(image, for: .normal)
    }
    
    func fill(with sideMenuItem: SideMenuItem) {
        self.sideMenuItem = sideMenuItem
        self.fill(with: sideMenuItem.icon, title: sideMenuItem.title)
    }
    
    // MARK: - Action
    
    @IBAction private func buttonAction(_ sender: UIButton) {
        self.delegate?.sideMenuActionView(self, didTapMenuItem: self.sideMenuItem)
    }
}

// MARK: - Themable
extension SideMenuActionView: Themable {
    
    func update(theme: Theme) {
        self.theme = theme
        
        self.button.setTitleColor(theme.textSecondaryColor, for: .normal)
        self.button.setTitleColor(theme.textSecondaryColor.withAlphaComponent(Constants.highlightedAlpha), for: .highlighted)
        self.button.tintColor = theme.textSecondaryColor
    }
}
