// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import CommonKit

class SplitViewUserIndicatorPresentationContext: UserIndicatorPresentationContext {
    private weak var splitViewController: UISplitViewController?
    private weak var masterCoordinator: SplitViewMasterCoordinatorProtocol?
    private weak var detailNavigationController: UINavigationController?
    
    init(
        splitViewController: UISplitViewController,
        masterCoordinator: SplitViewMasterCoordinatorProtocol,
        detailNavigationController: UINavigationController
    ) {
        self.splitViewController = splitViewController
        self.masterCoordinator = masterCoordinator
        self.detailNavigationController = detailNavigationController
    }
    
    var indicatorPresentingViewController: UIViewController? {
        guard
            let splitViewController = splitViewController,
            let masterCoordinator = masterCoordinator,
            let detailNavigationController = detailNavigationController
        else {
            MXLog.debug("[SplitViewCoordinator]: Missing tab bar or detail coordinator, cannot update user indicator presenter")
            return nil
        }
        return splitViewController.isCollapsed ? masterCoordinator.toPresentable() : detailNavigationController
    }
}
