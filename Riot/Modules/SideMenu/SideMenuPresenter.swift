// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

class SideMenuPresenter: SideMenuPresentable {

    // MARK: - Properties
    
    private let sideMenuCoordinator: SideMenuCoordinatorType
    
    // MARK: - Setup
    
    init(sideMenuCoordinator: SideMenuCoordinatorType) {
        self.sideMenuCoordinator = sideMenuCoordinator
    }
    
    // MARK: - Public
    
    func show(from presentable: Presentable, animated: Bool, completion: (() -> Void)?) {
        let presentingViewController = presentable.toPresentable()
        let sideMenuController = sideMenuCoordinator.toPresentable()
        
        presentingViewController.present(sideMenuController, animated: animated, completion: completion)
    }
    
    func dismiss(animated: Bool, completion: (() -> Void)?) {
        self.sideMenuCoordinator.toPresentable().dismiss(animated: animated, completion: completion)
    }
    
    @discardableResult func addScreenEdgePanGesturesToPresent(to view: UIView) -> UIScreenEdgePanGestureRecognizer {
        return sideMenuCoordinator.addScreenEdgePanGesturesToPresent(to: view)
    }
    
    @discardableResult func addPanGestureToPresent(to view: UIView) -> UIPanGestureRecognizer {
        return sideMenuCoordinator.addPanGestureToPresent(to: view)
    }
}
