// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit
import Reusable

/// Table view cell with only a text view spanning the whole content view, insets can be configured via `textView.textContainerInset`
class TextViewTableViewCell: UITableViewCell {

    @IBOutlet weak var textView: PlaceholderedTextView!
    
}

extension TextViewTableViewCell: NibReusable {}

extension TextViewTableViewCell: Themable {
    
    func update(theme: Theme) {
        textView.textColor = theme.textPrimaryColor
        textView.tintColor = theme.tintColor
        textView.placeholderColor = theme.placeholderTextColor
    }
    
}
