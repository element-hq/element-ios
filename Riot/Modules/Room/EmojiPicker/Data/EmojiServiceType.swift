/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol EmojiServiceType {
    
    /// Returns all available emoji categories. The completion will always be called on the main queue.
    func getEmojiCategories(completion: @escaping (MXResponse<[EmojiCategory]>) -> Void)
}
