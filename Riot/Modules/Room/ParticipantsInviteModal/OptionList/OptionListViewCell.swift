// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import Reusable

class OptionListViewCell: UITableViewCell, NibReusable {
    
    // MARK: - Properties
    
    @IBOutlet private weak var iconView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var detailLabel: UILabel!
    @IBOutlet private weak var selectionView: UIView!
    @IBOutlet private weak var chevronView: UIImageView!
    
    var isEnabled: Bool = true {
        didSet {
            self.contentView.alpha = isEnabled ? 1 : 0.3
        }
    }

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
        if isEnabled {
            super.setSelected(selected, animated: animated)

            UIView.animate(withDuration: animated ? 0.2 : 0.0) {
                self.selectionView.transform = selected ? .init(scaleX: 0.95, y: 0.95) : .identity
            }
        }
    }

    // MARK: - Public
    
    func update(with viewData: OptionListItemViewData) {
        self.iconView.image = viewData.image?.withRenderingMode(.alwaysTemplate)
        self.titleLabel.text = viewData.title
        self.detailLabel.text = viewData.detail
        self.chevronView.image = viewData.accessoryImage?.withRenderingMode(.alwaysTemplate)
        self.isEnabled = viewData.enabled
    }
    
    func update(theme: Theme) {
        self.theme = theme
        self.backgroundColor = theme.colors.background
        self.iconView.tintColor = theme.colors.secondaryContent
        
        self.titleLabel.textColor = theme.colors.primaryContent
        self.titleLabel.font = theme.fonts.bodySB
        
        self.detailLabel.textColor = theme.colors.secondaryContent
        self.detailLabel.font = theme.fonts.footnote
        
        self.selectionView.backgroundColor = theme.colors.quinaryContent
        
        self.chevronView.tintColor = theme.colors.quarterlyContent
    }
}
