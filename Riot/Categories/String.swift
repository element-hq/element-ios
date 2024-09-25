/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

extension String {

    private enum Constants {
        static let RTLOverrideChar: String = "\u{202E}"
    }
    
    /// Calculates a numeric hash same as Riot Web
    /// See original function here https://github.com/matrix-org/matrix-react-sdk/blob/321dd49db4fbe360fc2ff109ac117305c955b061/src/utils/FormattingUtils.js#L47
    var vc_hashCode: Int32 {
        var hash: Int32 = 0
        
        for character in self {
            let shiftedHash = hash << 5
            hash = shiftedHash.subtractingReportingOverflow(hash).partialValue + Int32(character.vc_unicodeScalarCodePoint)
        }
        return abs(hash)
    }
    
    /// Locale-independent case-insensitive contains
    /// Note: Prefer use `localizedCaseInsensitiveContains` when locale matters
    ///
    /// - Parameter other: The other string.
    /// - Returns: true if current string contains other string.
    func vc_caseInsensitiveContains(_ other: String) -> Bool {
        return self.range(of: other, options: .caseInsensitive) != nil
    }
    
    /// Returns a globally unique string
    static var vc_unique: String {
        return ProcessInfo.processInfo.globallyUniqueString
    }
    
    /// Returns a new string by removing all whitespaces from the receiver object
    /// - Returns: New string without whitespaces from the receiver
    func vc_removingAllWhitespaces() -> String {
        return components(separatedBy: .whitespaces).joined()
    }

    /// Returns if the string contains an RTL override character
    func vc_containsRTLOverride() -> Bool {
        return contains(Constants.RTLOverrideChar)
    }

    /// Returns a new string which is reversed of the receiver
    func vc_reversed() -> String {
        return String(self.reversed())
    }
    
    /// Returns nil if the string is empty or the string itself otherwise
    func vc_nilIfEmpty() -> String? {
        isEmpty ? nil : self
    }
}

extension Optional where Wrapped == String {
    
    var isEmptyOrNil: Bool {
        return self?.isEmpty ?? true
    }
}
