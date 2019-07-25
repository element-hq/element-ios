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
    let identifier: String
    let value: String
    let name: String
    let shortNames: [String]
    let keywords: [String]    
    let variations: [EmojiItem]
    
    init(identifier: String,
         value: String,
         name: String,
         shortNames: [String] = [],
         keywords: [String] = [],
         variations: [EmojiItem] = []) {
        
        self.identifier = identifier
        self.value = value
        self.name = name
        self.shortNames = shortNames
        self.keywords = keywords
        self.variations = variations
    }
}
