// 
// Copyright 2021 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

extension HTMLFormatter {
    /// Builds an attributed string by replacing a `%@` placeholder with the supplied link text and URL.
    /// - Parameters:
    ///   - string: The string to be formatted.
    ///   - link: The link text to be inserted.
    ///   - url: The URL to be linked to.
    /// - Returns: An attributed string.
    func format(_ string: String, with link: String, using url: URL) -> NSAttributedString {
        let baseString = NSMutableAttributedString(string: string)
        let attributedLink = NSAttributedString(string: link, attributes: [.link: url])
        
        let linkRange = (baseString.string as NSString).range(of: "%@")
        baseString.replaceCharacters(in: linkRange, with: attributedLink)
        
        return baseString
    }
}
