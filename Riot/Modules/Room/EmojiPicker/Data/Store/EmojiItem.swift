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
