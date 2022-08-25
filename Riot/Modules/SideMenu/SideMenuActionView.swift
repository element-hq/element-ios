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

import Reusable
import UIKit

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
    
    @IBOutlet private var button: UIButton!
    
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
        button.contentHorizontalAlignment = .left
        button.titleLabel?.lineBreakMode = .byTruncatingTail
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
    
    func fill(with image: UIImage, title: String) {
        button.setTitle(title, for: .normal)
        button.setImage(image, for: .normal)
    }
    
    func fill(with sideMenuItem: SideMenuItem) {
        self.sideMenuItem = sideMenuItem
        fill(with: sideMenuItem.icon, title: sideMenuItem.title)
    }
    
    // MARK: - Action
    
    @IBAction private func buttonAction(_ sender: UIButton) {
        delegate?.sideMenuActionView(self, didTapMenuItem: sideMenuItem)
    }
}

// MARK: - Themable

extension SideMenuActionView: Themable {
    func update(theme: Theme) {
        self.theme = theme
        
        button.setTitleColor(theme.textSecondaryColor, for: .normal)
        button.setTitleColor(theme.textSecondaryColor.withAlphaComponent(Constants.highlightedAlpha), for: .highlighted)
        button.tintColor = theme.textSecondaryColor
    }
}
