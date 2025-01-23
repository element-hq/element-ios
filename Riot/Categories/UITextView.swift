// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit

extension UITextView {
    /// Invalidates display for all text attachment inside the text view.
    @objc func vc_invalidateTextAttachmentsDisplay() {
        self.attributedText.enumerateAttribute(
            .attachment,
            in: NSRange(location: 0, length: self.attributedText.length),
            options: []) { value, range, _ in
                guard value != nil else {
                    return
                }
                self.layoutManager.invalidateDisplay(forCharacterRange: range)
            }
    }
}
