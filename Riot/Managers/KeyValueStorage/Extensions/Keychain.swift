// 
// Copyright 2020 New Vector Ltd
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
import KeychainAccess

/// Extension on Keychain to get/set booleans
extension Keychain {
    
    public func set(_ value: Bool, key: String, ignoringAttributeSynchronizable: Bool = true) throws {
        try set(value.description, key: key, ignoringAttributeSynchronizable: ignoringAttributeSynchronizable)
    }
    
    public func getBool(_ key: String, ignoringAttributeSynchronizable: Bool = true) throws -> Bool? {
        guard let value = try getString(key, ignoringAttributeSynchronizable: ignoringAttributeSynchronizable) else {
            return nil
        }
        guard value == true.description || value == false.description else { return nil }
        return value == true.description
    }
    
}
