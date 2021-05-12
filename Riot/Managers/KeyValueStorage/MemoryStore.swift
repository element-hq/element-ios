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
