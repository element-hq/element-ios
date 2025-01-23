// 
// Copyright 2024 New Vector Ltd.
// Copyright 2020 Vector Creations Ltd
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
