// 
// Copyright 2022 New Vector Ltd
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
