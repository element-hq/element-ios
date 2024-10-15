/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import UIKit
import Reusable

final class EmojiPickerHeaderView: UICollectionReusableView, NibReusable {
    
    // MARK: - Properties
    
    @IBOutlet private weak var titleLabel: UILabel!
    
    // MARK: - Public
    
    func update(theme: Theme) {
        self.backgroundColor = theme.headerBackgroundColor
        self.titleLabel.textColor = theme.headerTextPrimaryColor
    }
    
    func fill(with title: String) {
        titleLabel.text = title
    }
}
