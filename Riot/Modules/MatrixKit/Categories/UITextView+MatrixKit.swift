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

import UIKit

extension UITextView {
    private enum Constants {
        /// Distance threshold at which link can still be considered as "near" from location.
        static let linkHorizontalDistanceThreshold: CGFloat = 16.0
    }
    
    /// Determine if there is a link near a location point in UITextView bounds.
    ///
    /// - Parameters:
    ///   - point: The point inside the UITextView bounds
    /// - Returns: true to indicate that a link has been detected near the location point.
    @objc func isThereALinkNearPoint(_ point: CGPoint) -> Bool {
        guard bounds.contains(point),
              let textPosition = closestPosition(to: point)
        else {
            return false
        }

        // Depending on cursor position on a character containing both an attachment
        // and a link (e.g. a mention pill), a positive result can be retrieved either
        // from textStylingAtPosition or tokenizer's rangeEnclosingPosition.
        if let attributes = textStyling(at: textPosition, in: .forward),
           attributes[.link] != nil {
            // Using textStyling shouldn't provide false positives.
            return true
        } else if let textRange = tokenizer.rangeEnclosingPosition(textPosition,
                                                                   with: .character,
                                                                   inDirection: .layout(.left)) {
            let startIndex = offset(from: beginningOfDocument, to: textRange.start)
            if attributedText.attribute(.link, at: startIndex, effectiveRange: nil) != nil {
                // Fix false positives from tokenizer's rangeEnclosingPosition.
                // These occur if given point is located on the same line as a
                // trailing character containing a mention pill. Detected link is
                // rejected if actual distance from attachment trailing to point
                // is greater than linkHorizontalDistanceThreshold.
                let glyphIndex = layoutManager.glyphIndexForCharacter(at: startIndex)
                let attachmentWidth = layoutManager.attachmentSize(forGlyphAt: glyphIndex).width
                let glyphStartX = layoutManager.location(forGlyphAt: glyphIndex).x
                let distance = point.x - (glyphStartX + attachmentWidth)

                // TODO: improve using a range perhaps (beware of negative values when no attachment)
                return distance < Constants.linkHorizontalDistanceThreshold
            }
        }
            
        return false
    }
}
