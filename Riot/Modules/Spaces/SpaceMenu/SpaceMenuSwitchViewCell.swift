// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import Reusable

class SpaceMenuSwitchViewCell: UITableViewCell, SpaceMenuCell, NibReusable {
    
    // MARK: - Properties
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var selectionView: UIView!
    @IBOutlet private weak var switchView: UISwitch!

    // MARK: - Private
    
    private var theme: Theme?
    
    // MARK: - Life cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()

        self.selectionStyle = .none
        self.selectionView.layer.cornerRadius = 8.0
        self.selectionView.layer.masksToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        UIView.animate(withDuration: animated ? 0.3 : 0.0) {
            self.selectionView.alpha = selected ? 1.0 : 0.0
        }
    }

    // MARK: - Public
    
    func update(with viewData: SpaceMenuListItemViewData) {
        self.titleLabel.text = viewData.title
        self.switchView.isOn = (viewData.value as? Bool) ?? false
        
        viewData.delegate = self
    }
    
    func update(theme: Theme) {
        self.theme = theme
        self.backgroundColor = theme.colors.background
        self.titleLabel.textColor = theme.colors.primaryContent
        self.titleLabel.font = theme.fonts.body
        self.selectionView.backgroundColor = theme.colors.separator
    }
}

// MARK: - SpaceMenuListItemViewDataDelegate
extension SpaceMenuSwitchViewCell: SpaceMenuListItemViewDataDelegate {
    func spaceMenuItemValueDidChange(_ item: SpaceMenuListItemViewData) {
        self.switchView.setOn((item.value as? Bool) ?? false, animated: true)
    }
}
