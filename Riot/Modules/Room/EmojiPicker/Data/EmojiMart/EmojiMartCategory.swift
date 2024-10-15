/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

struct EmojiMartCategory {
    
    /// Emoji category identifier (e.g. "people")
    let identifier: String
    
    /// Emoji category name in english (e.g. "Smiley & People")
    let name: String
    
    /// List of emoji short names associated to the category (e.g. "people")
    let emojiShortNames: [String]
}

// MARK: - Decodable
extension EmojiMartCategory: Decodable {
    
    /// JSON keys associated to EmojiJSONCategory properties.
    enum CodingKeys: String, CodingKey {
        case identifier = "id"
        case name
        case emojiShortNames = "emojis"
    }
}
