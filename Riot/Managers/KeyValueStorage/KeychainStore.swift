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

class KeychainStore {
    
    private var keychain: Keychain
    
    /// Initializer
    /// - Parameter keychain: Keychain instance to be used to read/write
    init(withKeychain keychain: Keychain) {
        self.keychain = keychain
    }
    
}

extension KeychainStore: KeyValueStore {
    
    //  setters
    func set(_ value: Data?, forKey key: KeyValueStoreKey) throws {
        guard let value = value else {
            try removeObject(forKey: key)
            return
        }
        
        try keychain.set(value, key: key)
    }
    
    func set(_ value: String?, forKey key: KeyValueStoreKey) throws {
        guard let value = value else {
            try removeObject(forKey: key)
            return
        }
        
        try keychain.set(value, key: key)
    }
    
    func set(_ value: Bool?, forKey key: KeyValueStoreKey) throws {
        guard let value = value else {
            try removeObject(forKey: key)
            return
        }
        
        try keychain.set(value, key: key)
    }
    
    func set(_ value: Int?, forKey key: KeyValueStoreKey) throws {
        guard let value = value else {
            try removeObject(forKey: key)
            return
        }
        
        try keychain.set(String(value), key: key)
    }
    
    func set(_ value: UInt?, forKey key: KeyValueStoreKey) throws {
        guard let value = value else {
            try removeObject(forKey: key)
            return
        }
        
        try keychain.set(String(value), key: key)
    }
    
    //  getters
    func data(forKey key: KeyValueStoreKey) throws -> Data? {
        return try keychain.getData(key)
    }
    
    func string(forKey key: KeyValueStoreKey) throws -> String? {
        return try keychain.getString(key)
    }
    
    func bool(forKey key: KeyValueStoreKey) throws -> Bool? {
        return try keychain.getBool(key)
    }
    
    func integer(forKey key: KeyValueStoreKey) throws -> Int? {
        guard let stringValue = try keychain.getString(key) else {
            return nil
        }
        return Int(stringValue)
    }
    
    func unsignedInteger(forKey key: KeyValueStoreKey) throws -> UInt? {
        guard let stringValue = try keychain.getString(key) else {
            return nil
        }
        return UInt(stringValue)
    }
    
    //  checkers
    func containsObject(forKey key: KeyValueStoreKey) -> Bool {
        return (try? keychain.contains(key)) ?? false
    }
    
    //  remove
    func removeObject(forKey key: KeyValueStoreKey) throws {
        try keychain.remove(key)
    }
    
    func removeAll() throws {
        try keychain.removeAll()
    }
    
}
