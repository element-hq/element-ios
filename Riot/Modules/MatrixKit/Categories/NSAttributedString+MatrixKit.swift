// 
// Copyright 2024 New Vector Ltd.
// Copyright 2020 The Matrix.org Foundation C.I.C
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
