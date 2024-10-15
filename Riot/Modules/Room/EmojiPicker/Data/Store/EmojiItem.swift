/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

struct EmojiItem {
    
    // MARK: - Properties
    
    /// The commonly-agreed short name for the emoji, as supported in GitHub and others via the :short_name: syntax (e.g. "grinning" for 😀).
    let shortName: String
    
    /// The emoji string (e.g. 😀)
    let value: String
    
    /// The offical Unicode name (e.g. "Grinning Face" for 😀)
    let name: String
    
    /// An array of all the other known short names (e.g. ["running"] for 🏃‍♂️).
    let shortNames: [String]
    
    /// Associated emoji keywords (e.g. ["face","smile","happy"] for 😀).
    let keywords: [String]
    
    /// For emoji with multiple skin tone variations, a list of alternative emoji items.
    let variations: [EmojiItem]
    
    // MARK: - Setup
    
    init(shortName: String,
         value: String,
         name: String,
         shortNames: [String] = [],
         keywords: [String] = [],
         variations: [EmojiItem] = []) {
        
        self.shortName = shortName
        self.value = value
        self.name = name
        self.shortNames = shortNames
        self.keywords = keywords
        self.variations = variations
    }
}
