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
