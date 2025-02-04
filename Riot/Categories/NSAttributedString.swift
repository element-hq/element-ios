// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

public extension NSAttributedString {

    /// Returns a new attributed string by removing all links from the receiver.
    @objc var vc_byRemovingLinks: NSAttributedString {
        let result = NSMutableAttributedString(attributedString: self)
        result.removeAttribute(.link, range: NSRange(location: 0, length: length))
        return result
    }
    
    /// Enumerate attribute for given key and conveniently ignore any attribute that doesn't match given generic type.
    ///
    /// - Parameters:
    ///   - attrName: The name of the attribute to enumerate.
    ///   - enumerationRange: The range over which the attribute values are enumerated. If omitted, the entire range is used.
    ///   - opts: The options used by the enumeration. For possible values, see NSAttributedStringEnumerationOptions.
    ///   - block: The block to apply to ranges of the specified attribute in the attributed string.
    func vc_enumerateAttribute<T>(_ attrName: NSAttributedString.Key,
                                  in enumerationRange: NSRange? = nil,
                                  options opts: NSAttributedString.EnumerationOptions = [],
                                  using block: (T, NSRange, UnsafeMutablePointer<ObjCBool>) -> Void) {
        self.enumerateAttribute(attrName,
                                in: enumerationRange ?? .init(location: 0, length: length),
                                options: opts) { (attr: Any?, range: NSRange, stop: UnsafeMutablePointer<ObjCBool>) in
            guard let typedAttr = attr as? T else { return }
            
            block(typedAttr, range, stop)
        }
    }

    /// Creates a new attributed string with given alpha applied to all texts.
    ///
    /// - Parameters:
    ///   - alpha: Alpha value to apply
    /// - Returns: New attributed string with updated alpha
    @objc func withTextColorAlpha(_ alpha: CGFloat) -> NSAttributedString {
        let mutableString = NSMutableAttributedString(attributedString: self)
        mutableString.vc_enumerateAttribute(.foregroundColor) { (color: UIColor, range: NSRange, _) in
            let colorWithAlpha = color.withAlphaComponent(alpha)
            mutableString.addAttribute(.foregroundColor, value: colorWithAlpha, range: range)
        }

        return mutableString
    }
}
