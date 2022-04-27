// 
// Copyright 2022 New Vector Ltd
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

import CoreGraphics
import Foundation

extension Tools {
    /// Creates a new attributed string with given alpha applied to all texts.
    ///
    /// - Parameters:
    ///   - alpha: Alpha value to apply
    ///   - attributedString: Attributed string to update
    /// - Returns: New attributed string with updated alpha
    @objc static func setTextColorAlpha(_ alpha: CGFloat, inAttributedString attributedString: NSAttributedString) -> NSAttributedString {
        let totalRange = NSRange(location: 0, length: attributedString.length)
        let mutableString = NSMutableAttributedString(attributedString: attributedString)
        attributedString.vc_enumerateAttribute(.foregroundColor,
                                               in: totalRange) { (color: UIColor, range: NSRange, _) in
            let colorWithAlpha = color.withAlphaComponent(alpha)
            mutableString.addAttribute(.foregroundColor, value: colorWithAlpha, range: range)
        }
        
        return mutableString
    }
    
    /// Update alpha of all `PillTextAttachment` contained in given attributed string.
    ///
    /// - Parameters:
    ///   - alpha: Alpha value to apply
    ///   - attributedString: Attributed string containing the pills
    @objc static func setPillAlpha(_ alpha: CGFloat, inAttributedString attributedString: NSAttributedString) {
        let totalRange = NSRange(location: 0, length: attributedString.length)
        attributedString.vc_enumerateAttribute(.attachment,
                                               in: totalRange) { (pill: PillTextAttachment, range: NSRange, _) in
            pill.alpha = alpha
        }
    }
}
