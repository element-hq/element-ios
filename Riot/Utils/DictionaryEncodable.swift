// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// A type that can encode itself into a `[String: Any]` JSON dictionary.
protocol DictionaryEncodable: Encodable { }

enum DictionaryEncodableError: Error {
    /// The value returned an unexpected type from `JSONSerialization`.
    case typeError
}

extension DictionaryEncodable {
    /// Returns self encoded as a JSON dictionary.
    func dictionary() throws -> [String: Any] {
        let jsonData = try JSONEncoder().encode(self)
        let object = try JSONSerialization.jsonObject(with: jsonData)
        
        guard let dictionary = object as? [String: Any] else {
            MXLog.error("[DictionaryEncodable] Unexpected type decoded, expected a Dictionary.", context: [
                "type": type(of: object)
            ])
            throw DictionaryEncodableError.typeError
        }
        
        return dictionary
    }
}
