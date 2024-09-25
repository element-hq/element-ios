/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol SerializationServiceType {
    func deserialize<T: Decodable>(_ data: Data) throws -> T
    func deserialize<T: Decodable>(_ object: Any) throws -> T
    
    func serialize<T: Encodable>(_ object: T) throws -> Data
}
