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

import Foundation

/// Used for storing and resolving dependencies at runtime.
struct DependencyContainer {
    
    // Stores the dependencies with type information removed.
    private var dependencyStore: [String: Any] = [:]
    
    /// Resolve a dependency by type.
    ///
    /// Given a particular `Type` (Inferred from return type),
    /// generate a key and retrieve from storage.
    /// 
    /// - Returns: The resolved dependency.
    func resolve<T>() -> T {
        let key = String(describing: T.self)
        guard let t = dependencyStore[key] as? T else {
            fatalError("No provider registered for type \(T.self)")
        }
        return t
    }
    
    /// Register a dependency.
    ///
    /// Given a dependency, generate a key from it's `Type` and save in storage.
    /// - Parameter dependency: The dependency to register.
    mutating func register<T>(dependency: T) {
        let key = String(describing: T.self)
        dependencyStore[key] = dependency
    }
}
