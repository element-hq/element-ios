/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import UIKit
import Reusable

final class EditHistoryHeaderView: UITableViewHeaderFooterView, NibLoadable, Reusable, Themable {
    
    // MARK: - Properties
    
    @IBOutlet private weak var dateLabel: UILabel!
    
    // MARK: - Public
    
    func update(theme: Theme) {
        self.contentView.backgroundColor = theme.backgroundColor
        self.dateLabel.textColor = theme.headerTextPrimaryColor
    }
    
    func fill(with dateString: String) {
        self.dateLabel.text = dateString
    }
}
