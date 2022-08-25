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

class SpaceMenuListViewCell: UITableViewCell, SpaceMenuCell, NibReusable {
    // MARK: - Properties
    
    @IBOutlet private var iconView: UIImageView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var betaView: UIView!
    @IBOutlet private var betaLabel: UILabel!
    @IBOutlet private var selectionView: UIView!

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
        super.setSelected(selected, animated: animated)

        UIView.animate(withDuration: animated ? 0.3 : 0.0) {
            self.selectionView.alpha = selected ? 1.0 : 0.0
        }
    }

    // MARK: - Public
    
    func update(with viewData: SpaceMenuListItemViewData) {
        iconView.image = viewData.icon
        titleLabel.text = viewData.title
        
        guard let theme = theme else {
            return
        }
        
        if viewData.style == .destructive {
            titleLabel.textColor = theme.colors.alert
            iconView.tintColor = theme.colors.alert
        } else {
            titleLabel.textColor = theme.colors.primaryContent
            iconView.tintColor = theme.colors.secondaryContent
        }
        
        betaView.layer.masksToBounds = true
        betaView.layer.cornerRadius = 4
        betaView.isHidden = !viewData.isBeta
    }
    
    func update(theme: Theme) {
        self.theme = theme
        backgroundColor = theme.colors.background
        iconView.tintColor = theme.colors.secondaryContent
        titleLabel.textColor = theme.colors.primaryContent
        titleLabel.font = theme.fonts.body
        selectionView.backgroundColor = theme.colors.separator
        betaLabel.font = theme.fonts.caption2SB
        betaLabel.textColor = theme.colors.secondaryContent
        betaView.backgroundColor = theme.colors.quinaryContent
    }
}
