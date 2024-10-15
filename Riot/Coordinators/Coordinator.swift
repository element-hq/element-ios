/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import UIKit

/// Protocol describing a [Coordinator](http://khanlou.com/2015/10/coordinators-redux/).
/// Coordinators are the objects which control the navigation flow of the application.
/// It helps to isolate and reuse view controllers and pass dependencies down the navigation hierarchy.
protocol Coordinator: AnyObject {
    
    /// Starts job of the coordinator.
    func start()
    
    /// Child coordinators to retain. Prevent them from getting deallocated.
    var childCoordinators: [Coordinator] { get set }
    
    /// Stores coordinator to the `childCoordinators` array.
    ///
    /// - Parameter childCoordinator: Child coordinator to store.
    func add(childCoordinator: Coordinator)
    
    /// Remove coordinator from the `childCoordinators` array.
    ///
    /// - Parameter childCoordinator: Child coordinator to remove.
    func remove(childCoordinator: Coordinator)
}

// `Coordinator` default implementation
extension Coordinator {
    
    func add(childCoordinator coordinator: Coordinator) {
        childCoordinators.append(coordinator)
    }
    
    func remove(childCoordinator: Coordinator) {
        self.childCoordinators = self.childCoordinators.filter { $0 !== childCoordinator }
    }
}
