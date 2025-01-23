// 
// Copyright 2024 New Vector Ltd.
// Copyright 2020 Vector Creations Ltd
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
