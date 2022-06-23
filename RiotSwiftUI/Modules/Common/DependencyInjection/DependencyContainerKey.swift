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
import SwiftUI

/// An Environment Key for retrieving runtime dependencies.
///
/// Dependencies are to be injected into `ObservableObjects`
/// that are owned by a View (i.e. `@StateObject`'s, such as ViewModels owned by the View).
private struct DependencyContainerKey: EnvironmentKey {
    static let defaultValue = DependencyContainer()
}

extension EnvironmentValues {
    var dependencies: DependencyContainer {
        get { self[DependencyContainerKey.self] }
        set { self[DependencyContainerKey.self] = newValue }
    }
}

extension View {
    
    /// A modifier for adding a dependency to the SwiftUI view hierarchy's dependency container.
    ///
    /// Important: When adding a dependency to cast it to the type in which it will be injected.
    /// So if adding `MockDependency` but type at injection is `Dependency` remember to cast
    /// to `Dependency` first.
    /// - Parameter dependency: The dependency to add.
    /// - Returns: The wrapped view that now includes the dependency.
    func addDependency<T>(_ dependency: T) -> some View {
        transformEnvironment(\.dependencies) { container in
            container.register(dependency: dependency)
        }
    }
}
