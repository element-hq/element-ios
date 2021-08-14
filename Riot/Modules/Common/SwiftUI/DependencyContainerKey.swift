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

private struct DependencyContainerKey: EnvironmentKey {
    static let defaultValue = DependencyContainer()
}

@available(iOS 14.0, *)
extension EnvironmentValues {
    var dependencies: DependencyContainer {
        get { self[DependencyContainerKey.self] }
        set { self[DependencyContainerKey.self] = newValue }
    }
}

/**
 */
@available(iOS 14.0, *)
extension View {
    func setDependencies(_ container: DependencyContainer) -> some View {
        environment(\.dependencies, container)
    }
    
    func addDependency<T>(_ dependency: T) -> some View {
        transformEnvironment(\.dependencies) { container in
            container.register(dependency: dependency)
        }
    }
}
