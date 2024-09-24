// File created from ScreenTemplate
// $ createScreen.sh toto EmojiPicker
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

/// EmojiPickerViewController view state
enum EmojiPickerViewState {
    case loading
    case loaded(emojiCategories: [EmojiPickerCategoryViewData])
    case error(Error)
}
