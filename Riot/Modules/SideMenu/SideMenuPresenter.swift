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
