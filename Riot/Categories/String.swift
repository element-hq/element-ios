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
