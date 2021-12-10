// 
// Copyright 2020 The Matrix.org Foundation C.I.C
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

public extension NSAttributedString {
    /// Returns a string created by joining all ranges of the attributed string that don't have
    /// the `kMXKToolsBlockquoteMarkAttribute` attribute.
    @objc func mxk_unquotedString() -> NSString? {
        var unquotedSubstrings = [String]()
        
        enumerateAttributes(in: NSRange(location: 0, length: self.length), options: []) { attributes, range, stop in
            guard !attributes.keys.contains(where: { $0.rawValue == kMXKToolsBlockquoteMarkAttribute }) else { return }
            unquotedSubstrings.append(self.attributedSubstring(from: range).string)
        }
        
        return unquotedSubstrings.joined(separator: " ") as NSString
    }
}
