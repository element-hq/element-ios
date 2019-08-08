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

extension EmojiItem: Decodable {

    /// JSON keys associated to EmojiItem properties.
    /// See https://github.com/missive/emoji-mart/blob/master/src/utils/data.js for minified letters informations.
    ///
    /// - shortName: The commonly-agreed short name for the emoji, as supported in GitHub and others via the :short_name: syntax.
    /// - name: The offical Unicode name.
    /// - codepoint: The Unicode codepoint, as 4-5 hex digits. Where an emoji needs 2 or more codepoints, they are specified like 1F1EA-1F1F8.
    /// - shortNames: An array of all the other known short names.
    /// - keywords: Associated emoji keywords.
    enum CodingKeys: String, CodingKey {
        case shortName
        case name = "a"
        case codepoint = "b"
        case shortNames = "n"
        case keywords = "j"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        guard let shortName = decoder.codingPath.last?.stringValue else {
            throw DecodingError.dataCorruptedError(forKey: .shortName, in: container, debugDescription: "Cannot initialize short name")
        }
        
        let emojiUnicodeStringValue = try container.decode(String.self, forKey: .codepoint)
        
        let unicodeStringComponents = emojiUnicodeStringValue.components(separatedBy: "-")
        
        var emoji = ""
        
        for unicodeStringComponent in unicodeStringComponents {
            if let unicodeCodePoint = Int(unicodeStringComponent, radix: 16),
                let emojiUnicodeScalar = UnicodeScalar(unicodeCodePoint) {
                emoji.append(String(emojiUnicodeScalar))
            } else {
                throw DecodingError.dataCorruptedError(forKey: .codepoint, in: container, debugDescription: "Cannot initialize emoji")
            }
        }
        
        let name = try container.decode(String.self, forKey: .name)
        
        let shortNames: [String]
        
        if let decodedShortNames = try container.decodeIfPresent([String].self, forKey: .shortNames) {
            shortNames = decodedShortNames
        } else {
            shortNames = []
        }
        
        let keywords: [String]
        
        if let decodedKeywords = try container.decodeIfPresent([String].self, forKey: .keywords) {
            keywords = decodedKeywords
        } else {
            keywords = []
        }
        
        self.init(shortName: shortName,
                  value: emoji,
                  name: name,
                  shortNames: shortNames,
                  keywords: keywords)
    }
}
