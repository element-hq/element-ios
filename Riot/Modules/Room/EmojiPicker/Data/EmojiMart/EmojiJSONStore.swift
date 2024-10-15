/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

struct EmojiMartStore {
    let categories: [EmojiJSONCategory]
    let emojis: [EmojiItem]
}

// MARK: - Decodable
extension EmojiMartStore: Decodable {
    
    /// JSON keys associated to EmojiJSONStore properties.
    enum CodingKeys: String, CodingKey {
        case categories
        case emojis
    }
    
    /// JSON key associated to emoji short name.
    struct EmojiKey: CodingKey {
        var stringValue: String
        
        init?(stringValue: String) {
            self.stringValue = stringValue
        }
        
        var intValue: Int? { return nil }
        init?(intValue: Int) { return nil }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let emojisContainer = try container.nestedContainer(keyedBy: EmojiKey.self, forKey: .emojis)
        
        let emojis: [EmojiItem] = emojisContainer.allKeys.compactMap { (emojiKey) -> EmojiItem? in
            let emojiItem: EmojiItem?
            
            do {
                emojiItem = try emojisContainer.decode(EmojiItem.self, forKey: emojiKey)
            } catch {
                MXLog.debug("[EmojiJSONStore] init(from decoder: Decoder) failed to parse emojiItem \(emojiKey) with error: \(error)")
                emojiItem = nil
            }
            
            return emojiItem
        }
        
        let categories = try container.decode([EmojiJSONCategory].self, forKey: .categories)
        
        self.init(categories: categories, emojis: emojis)
    }
}
