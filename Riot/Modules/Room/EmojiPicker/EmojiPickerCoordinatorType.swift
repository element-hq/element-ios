// File created from ScreenTemplate
// $ createScreen.sh toto EmojiPicker
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol EmojiPickerCoordinatorDelegate: AnyObject {
    func emojiPickerCoordinator(_ coordinator: EmojiPickerCoordinatorType, didAddEmoji emoji: String, forEventId eventId: String)
    func emojiPickerCoordinator(_ coordinator: EmojiPickerCoordinatorType, didRemoveEmoji emoji: String, forEventId eventId: String)
    func emojiPickerCoordinatorDidCancel(_ coordinator: EmojiPickerCoordinatorType)
}

/// `EmojiPickerCoordinatorType` is a protocol describing a Coordinator that handle emoji picker navigation flow.
protocol EmojiPickerCoordinatorType: Coordinator, Presentable {
    var delegate: EmojiPickerCoordinatorDelegate? { get }
}
