/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

final class EmojiStore {
    
    static let shared = EmojiStore()
    
    // MARK: - Properties
    
    private var emojiCategories: [EmojiCategory] = []
    
    // MARK: - Public
    
    func getAll() -> [EmojiCategory] {
        return self.emojiCategories
    }
    
    func set(_ emojiCategories: [EmojiCategory]) {
        self.emojiCategories = emojiCategories
    }
    
    func findEmojiItemsSortedByCategory(with searchText: String) -> [EmojiCategory] {
        let initial: [EmojiCategory] = []
        
        let filteredEmojiCategories = emojiCategories.reduce(into: initial) { (filteredEmojiCategories, emojiCategory) in
            
            let filteredEmojiItems = emojiCategory.emojis.filter({ (emojiItem) -> Bool in
                
                // Do not use `String.localizedCaseInsensitiveContains` here as EmojiItem data is not localized for the moment
                
                if emojiItem.shortName.vc_caseInsensitiveContains(searchText) {
                    return true
                }

                if emojiItem.name.vc_caseInsensitiveContains(searchText) {
                    return true
                }
                
                if emojiItem.keywords.contains(where: { $0.vc_caseInsensitiveContains(searchText) }) {
                    return true
                }
                
                let shortNamesMatch = emojiItem.shortNames.contains { text -> Bool in
                    return text.vc_caseInsensitiveContains(searchText)
                }
                
                return shortNamesMatch
            })
            
            if filteredEmojiItems.isEmpty == false {
                let filteredEmojiCategory = EmojiCategory(identifier: emojiCategory.identifier, emojis: filteredEmojiItems)
                filteredEmojiCategories.append(filteredEmojiCategory)
            }
        }
        
        return filteredEmojiCategories
    }
}
