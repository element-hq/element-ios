// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
