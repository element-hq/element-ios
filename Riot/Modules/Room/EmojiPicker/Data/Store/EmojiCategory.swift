/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

struct EmojiCategory {
    
    /// Emoji category identifier (e.g. "people")
    let identifier: String
    
    /// Emoji list associated to category
    let emojis: [EmojiItem]
    
    /// Emoji category localized name
    var name: String {
        let categoryNameLocalizationKey = "emoji_picker_\(self.identifier)_category"
        return VectorL10n.tr("Vector", categoryNameLocalizationKey)
    }
}
