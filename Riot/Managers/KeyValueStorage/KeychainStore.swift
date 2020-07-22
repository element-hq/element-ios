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
    
    private let keychain = Keychain()
    
    func setObject(forKey key: KeyValueStoreKey, value: Any?) {
        if value == nil {
            removeObject(forKey: key)
            return
        }
        
        if let value = value as? String {
            try? keychain.set(value, key: key)
        } else if let value = value as? Data {
            try? keychain.set(value, key: key)
        }
    }

    func getObject(forKey key: KeyValueStoreKey) -> Any? {
        return try? keychain.get(key)
    }
    
    func removeObject(forKey key: KeyValueStoreKey) {
        try? keychain.remove(key)
    }
    
}
