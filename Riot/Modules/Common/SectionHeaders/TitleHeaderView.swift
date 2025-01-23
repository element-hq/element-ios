// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import Reusable

class TitleHeaderView: UITableViewHeaderFooterView {
    
    @IBOutlet weak var label: UILabel!
    
    func update(title: String) {
        label.text = title.uppercased()
    }
    
}


extension TitleHeaderView: NibReusable {}
extension TitleHeaderView: Themable {
    
    func update(theme: Theme) {
        contentView.backgroundColor = theme.headerBackgroundColor
        label.textColor = theme.headerTextSecondaryColor
        label.font = theme.fonts.body
    }
}
