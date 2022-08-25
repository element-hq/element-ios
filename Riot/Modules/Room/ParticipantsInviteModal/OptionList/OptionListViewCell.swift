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

import Foundation
import Reusable

class OptionListViewCell: UITableViewCell, NibReusable {
    // MARK: - Properties
    
    @IBOutlet private var iconView: UIImageView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var detailLabel: UILabel!
    @IBOutlet private var selectionView: UIView!
    @IBOutlet private var chevronView: UIImageView!
    
    var isEnabled = true {
        didSet {
            contentView.alpha = isEnabled ? 1 : 0.3
        }
    }

    // MARK: - Private
    
    private var theme: Theme?
    
    // MARK: - Life cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()

        selectionStyle = .none
        selectionView.layer.cornerRadius = 8.0
        selectionView.layer.masksToBounds = true
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
        iconView.image = viewData.image?.withRenderingMode(.alwaysTemplate)
        titleLabel.text = viewData.title
        detailLabel.text = viewData.detail
        chevronView.image = viewData.accessoryImage?.withRenderingMode(.alwaysTemplate)
        isEnabled = viewData.enabled
    }
    
    func update(theme: Theme) {
        self.theme = theme
        backgroundColor = theme.colors.background
        iconView.tintColor = theme.colors.secondaryContent
        
        titleLabel.textColor = theme.colors.primaryContent
        titleLabel.font = theme.fonts.bodySB
        
        detailLabel.textColor = theme.colors.secondaryContent
        detailLabel.font = theme.fonts.footnote
        
        selectionView.backgroundColor = theme.colors.quinaryContent
        
        chevronView.tintColor = theme.colors.quarterlyContent
    }
}
