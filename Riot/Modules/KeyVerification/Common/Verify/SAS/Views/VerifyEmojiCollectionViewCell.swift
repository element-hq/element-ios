/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import UIKit
import Reusable

class VerifyEmojiCollectionViewCell: UICollectionViewCell, Reusable, Themable {
    @IBOutlet weak var emoji: UILabel!
    @IBOutlet weak var name: UILabel!

    func update(theme: Theme) {
        name.textColor = theme.textPrimaryColor
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        emoji.isAccessibilityElement = false
    }
}
