// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// `NavigationRouterStoreProtocol` describes a structure that enables to get a NavigationRouter from a UINavigationController instance.
protocol NavigationRouterStoreProtocol {
    
    /// Gets the existing navigation router for the supplied controller, creating a new one if it doesn't yet exist.
    /// Note: The store only holds a weak reference to the returned router. It is the caller's responsibility to retain it.
    func navigationRouter(for navigationController: UINavigationController) -> NavigationRouterType
}
