// 
// Copyright 2020 Vector Creations Ltd
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

@objcMembers
/// Only supports `String` and `Data` values for now.
class KeychainStore: KeyValueStore {
    
    private var keychain: Keychain
    
    /// Initializer
    /// - Parameter keychain: Keychain instance to be used to read/write
    init(withKeychain keychain: Keychain) {
        self.keychain = keychain
    }
    
    func set(_ value: Any?, forKey key: KeyValueStoreKey) throws {
        if value == nil {
            try removeObject(forKey: key)
            return
        }
        
        if let value = value as? String {
            try keychain.set(value, key: key)
        } else if let value = value as? Data {
            try keychain.set(value, key: key)
        }
    }

    func object(forKey key: KeyValueStoreKey) throws -> Any? {
        return try keychain.get(key)
    }
    
    func removeObject(forKey key: KeyValueStoreKey) throws {
        try keychain.remove(key)
    }
    
}
