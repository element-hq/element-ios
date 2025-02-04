// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit

extension UITextView {
    private enum Constants {
        /// Distance threshold at which linkified text attachment can still be considered as "near" location.
        static let attachmentLinkHorizontalDistanceThreshold: CGFloat = 16.0
    }
    
    /// Determine if there is a link near a location point in UITextView bounds.
    ///
    /// - Parameters:
    ///   - point: The point inside the UITextView bounds
    /// - Returns: true to indicate that a link has been detected near the location point.
    @objc func isThereALinkNearLocation(_ point: CGPoint) -> Bool {
        return urlForLinkAtLocation(point) != nil
    }
    
    /// Detect link near a location point in UITextView bounds.
    ///
    /// - Parameter point: The point inside the UITextView bounds
    /// - Returns: link detected at given location
    @objc func urlForLinkAtLocation(_ point: CGPoint) -> URL? {
        guard bounds.contains(point),
              let textPosition = closestPosition(to: point)
        else {
            return nil
        }
        
        // The value of `NSLinkAttributeName` attribute could be an URL or a String object.
        func attributeToLink(_ attribute: Any) -> URL? {
            if let link = attribute as? URL {
                return link
            } else if let stringURL = attribute as? String {
                return URL(string: stringURL)
            } else {
                return nil
            }
        }
        
        // Depending on cursor position on a character containing both an attachment
        // and a link (e.g. a mention pill), a positive result can be retrieved either
        // from textStylingAtPosition or tokenizer's rangeEnclosingPosition.
        if let attributes = textStyling(at: textPosition, in: .forward),
           let linkAttribute = attributes[.link] {
            // Using textStyling shouldn't provide false positives.
            return attributeToLink(linkAttribute)
        } else if let textRange = tokenizer.rangeEnclosingPosition(textPosition,
                                                                   with: .character,
                                                                   inDirection: .layout(.left)) {
            let startIndex = offset(from: beginningOfDocument, to: textRange.start)
            if let linkAttribute = attributedText.attribute(.link, at: startIndex, effectiveRange: nil) {
                // Fix false positives from tokenizer's rangeEnclosingPosition.
                // These occur if given point is located on the same line as a
                // trailing linkified text attachment. Detected link is
                // rejected if actual distance from attachment trailing to point
                // is greater than linkHorizontalDistanceThreshold.
                let glyphIndex = layoutManager.glyphIndexForCharacter(at: startIndex)
                let attachmentWidth = layoutManager.attachmentSize(forGlyphAt: glyphIndex).width
                // Width is -1 when there is no attachment.
                if attachmentWidth > 0 {
                    let glyphStartX = layoutManager.location(forGlyphAt: glyphIndex).x
                    let start = glyphStartX - Constants.attachmentLinkHorizontalDistanceThreshold
                    let end = glyphStartX + attachmentWidth + Constants.attachmentLinkHorizontalDistanceThreshold
                    let range = (start...end)
                    
                    return range.contains(point.x) ? attributeToLink(linkAttribute) : nil
                }
            }
        }
            
        return nil
    }
}
