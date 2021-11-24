// 
// Copyright 2021 New Vector Ltd
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

protocol DictionaryConvertible: Encodable {
    var dictionary: [String: Any] { get }
}

extension DictionaryConvertible {
    var dictionary: [String: Any] {
        let mirror = Mirror(reflecting: self)
        let dict: [String: Any] = Dictionary(uniqueKeysWithValues: mirror.children.compactMap { (label: String?, value: Any) in
            guard let label = label else { return nil }
            
            // Handle standard types such as String/Int/Bool
            if let value = value as? NSCoding {
                return (label, value)
            }
            
            // AnalyticsEvent enums
            if let value = value as? CustomStringConvertible {
                return (label, value.description)
            }
            
            return nil
        })
        
        return dict
    }
}
