// 
// Copyright 2024 New Vector Ltd.
// Copyright 2020 Vector Creations Ltd
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

class MemoryStore {
    
    private(set) var map: [KeyValueStoreKey: Any] = [:]
    
    private func setObject(_ value: Any?, forKey key: KeyValueStoreKey) {
        if let value = value {
            map[key] = value
        } else {
            try? removeObject(forKey: key)
        }
    }

    private func object(forKey key: KeyValueStoreKey) -> Any? {
        return map[key]
    }
    
    init(withMap map: [KeyValueStoreKey: Any] = [:]) {
        self.map = map
    }

}

extension MemoryStore: KeyValueStore {
    
    //  setters
    func set(_ value: Data?, forKey key: KeyValueStoreKey) throws {
        setObject(value, forKey: key)
    }
    
    func set(_ value: String?, forKey key: KeyValueStoreKey) throws {
        setObject(value, forKey: key)
    }
    
    func set(_ value: Bool?, forKey key: KeyValueStoreKey) throws {
        setObject(value, forKey: key)
    }
    
    func set(_ value: Int?, forKey key: KeyValueStoreKey) throws {
        setObject(value, forKey: key)
    }
    
    func set(_ value: UInt?, forKey key: KeyValueStoreKey) throws {
        setObject(value, forKey: key)
    }
    
    //  getters
    func data(forKey key: KeyValueStoreKey) throws -> Data? {
        return object(forKey: key) as? Data
    }
    
    func string(forKey key: KeyValueStoreKey) throws -> String? {
        return object(forKey: key) as? String
    }
    
    func bool(forKey key: KeyValueStoreKey) throws -> Bool? {
        return object(forKey: key) as? Bool
    }
    
    func integer(forKey key: KeyValueStoreKey) throws -> Int? {
        return object(forKey: key) as? Int
    }
    
    func unsignedInteger(forKey key: KeyValueStoreKey) throws -> UInt? {
        return object(forKey: key) as? UInt
    }
    
    //  checkers
    func containsObject(forKey key: KeyValueStoreKey) -> Bool {
        return object(forKey: key) != nil
    }
    
    //  remove
    func removeObject(forKey key: KeyValueStoreKey) throws {
        map.removeValue(forKey: key)
    }
    
    func removeAll() throws {
        map.removeAll()
    }
    
}
