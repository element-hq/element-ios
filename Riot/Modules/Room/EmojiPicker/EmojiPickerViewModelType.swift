// File created from ScreenTemplate
// $ createScreen.sh toto EmojiPicker
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol EmojiPickerViewModelViewDelegate: AnyObject {
    func emojiPickerViewModel(_ viewModel: EmojiPickerViewModelType, didUpdateViewState viewSate: EmojiPickerViewState)
}

protocol EmojiPickerViewModelCoordinatorDelegate: AnyObject {
    func emojiPickerViewModel(_ viewModel: EmojiPickerViewModelType, didAddEmoji emoji: String, forEventId eventId: String)
    func emojiPickerViewModel(_ viewModel: EmojiPickerViewModelType, didRemoveEmoji emoji: String, forEventId eventId: String)
    func emojiPickerViewModelDidCancel(_ viewModel: EmojiPickerViewModelType)
}

/// Protocol describing the view model used by `EmojiPickerViewController`
protocol EmojiPickerViewModelType {
            
    var viewDelegate: EmojiPickerViewModelViewDelegate? { get set }
    var coordinatorDelegate: EmojiPickerViewModelCoordinatorDelegate? { get set }
    
    func process(viewAction: EmojiPickerViewAction)
}
