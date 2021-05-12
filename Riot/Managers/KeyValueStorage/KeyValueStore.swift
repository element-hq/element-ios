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

typealias KeyValueStoreKey = String

protocol KeyValueStore {
    //  setters
    func set(_ value: Data?, forKey key: KeyValueStoreKey) throws
    func set(_ value: String?, forKey key: KeyValueStoreKey) throws
    func set(_ value: Bool?, forKey key: KeyValueStoreKey) throws
    func set(_ value: Int?, forKey key: KeyValueStoreKey) throws
    func set(_ value: UInt?, forKey key: KeyValueStoreKey) throws
    
    //  getters
    func data(forKey key: KeyValueStoreKey) throws -> Data?
    func string(forKey key: KeyValueStoreKey) throws -> String?
    func bool(forKey key: KeyValueStoreKey) throws -> Bool?
    func integer(forKey key: KeyValueStoreKey) throws -> Int?
    func unsignedInteger(forKey key: KeyValueStoreKey) throws -> UInt?
    
    //  checkers
    func containsObject(forKey key: KeyValueStoreKey) -> Bool
    
    //  remove
    func removeObject(forKey key: KeyValueStoreKey) throws
    func removeAll() throws
}
