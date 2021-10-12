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

/// `NavigationRouterStoreProtocol` describes a structure that enables to get a NavigationRouter from a UINavigationController instance.
protocol NavigationRouterStoreProtocol {
    
    /// Gets the existing navigation router for the supplied controller, creating a new one if it doesn't yet exist.
    /// Note: The store only holds a weak reference to the returned router. It is the caller's responsibility to retain it.
    func navigationRouter(for navigationController: UINavigationController) -> NavigationRouterType
}
