/*
 Copyright 2019 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
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
