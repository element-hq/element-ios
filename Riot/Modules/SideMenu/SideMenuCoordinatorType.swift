// File created from ScreenTemplate
// $ createScreen.sh SideMenu SideMenu
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol SideMenuCoordinatorDelegate: AnyObject {
    func sideMenuCoordinator(_ coordinator: SideMenuCoordinatorType, didTapMenuItem menuItem: SideMenuItem, fromSourceView sourceView: UIView)
}

/// `SideMenuCoordinatorType` is a protocol describing a Coordinator that handle key backup setup passphrase navigation flow.
protocol SideMenuCoordinatorType: Coordinator, Presentable {
    var delegate: SideMenuCoordinatorDelegate? { get }
    
    @discardableResult func addScreenEdgePanGesturesToPresent(to view: UIView) -> UIScreenEdgePanGestureRecognizer
    @discardableResult func addPanGestureToPresent(to view: UIView) -> UIPanGestureRecognizer
    func select(spaceWithId spaceId: String)
}
