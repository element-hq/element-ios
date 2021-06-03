/*
 Copyright 2019 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
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
