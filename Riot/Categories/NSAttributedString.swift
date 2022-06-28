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
