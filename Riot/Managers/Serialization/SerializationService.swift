/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

final class SerializationService: SerializationServiceType {
    
    // MARK: - Properties
    
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    // MARK: - Public
    
    func deserialize<T: Decodable>(_ data: Data) throws -> T {
        return try decoder.decode(T.self, from: data)
    }

    func deserialize<T: Decodable>(_ object: Any) throws -> T {
        let jsonData: Data

        if let data = object as? Data {
            jsonData = data
        } else {
            jsonData = try JSONSerialization.data(withJSONObject: object, options: [])
        }
        return try decoder.decode(T.self, from: jsonData)
    }
    
    
    func serialize<T: Encodable>(_ object: T) throws -> Data {
        return try encoder.encode(object)
    }
}
