// 
// Copyright 2021 New Vector Ltd
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

// Taken from https://www.swiftbysundell.com/articles/property-wrappers-in-swift/

import Foundation

@propertyWrapper
struct UserDefault<Value> {
    
    private let key: String
    private let defaultValue: Value
    private let storage: UserDefaults
    
    init(key: String, defaultValue: Value, storage: UserDefaults = .standard) {
        self.defaultValue = defaultValue
        self.key = key
        self.storage = storage
    }
    
    var wrappedValue: Value {
        get {
            let value = storage.value(forKey: key) as? Value
            return value ?? defaultValue
        }
        set {
            if let optional = newValue as? AnyOptional, optional.isNil {
                storage.removeObject(forKey: key)
            } else {
                storage.setValue(newValue, forKey: key)
            }
            let tmpKey = key
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .userDefaultValueUpdated,
                                                object: tmpKey)
            }
        }
    }
}

extension UserDefault where Value: ExpressibleByNilLiteral {
    init(key: String, storage: UserDefaults = .standard) {
        self.init(key: key, defaultValue: nil, storage: storage)
    }
}

private protocol AnyOptional {
    var isNil: Bool { get }
}

extension Optional: AnyOptional {
    var isNil: Bool { self == nil }
}

extension Notification.Name {
    static let userDefaultValueUpdated = Notification.Name("userDefaultValueUpdated")
}
