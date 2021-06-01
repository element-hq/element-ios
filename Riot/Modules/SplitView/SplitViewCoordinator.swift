/*
 Copyright 2020 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import Foundation

/// SplitViewCoordinatorParameters input parameters
class SplitViewCoordinatorParameters {
    
    let router: RootRouterType
    let userSessionsService: UserSessionsService
    
    init(router: RootRouterType, userSessionsService: UserSessionsService) {
        self.router = router
        self.userSessionsService = userSessionsService
    }
}

final class SplitViewCoordinator: NSObject, SplitViewCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private    
    
    private let parameters: SplitViewCoordinatorParameters
    
    private let splitViewController: UISplitViewController
    
    private weak var masterPresentable: SplitViewMasterPresentable?
    private var detailNavigationController: UINavigationController?
    
    private weak var tabBarCoordinator: TabBarCoordinatorType?
    
    // MARK: Public
    
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: SplitViewCoordinatorDelegate?
    
    // MARK: - Setup
            
    init(parameters: SplitViewCoordinatorParameters) {
        self.parameters = parameters
        
        let splitViewController = RiotSplitViewController()
        splitViewController.preferredDisplayMode = .allVisible
        self.splitViewController = splitViewController
    }
    
    // MARK: - Public methods
    
    func start() {
        self.splitViewController.delegate = self
        
        let tabBarCoordinator = self.createTabBarCoordinator()
        tabBarCoordinator.delegate = self
        tabBarCoordinator.splitViewMasterPresentableDelegate = self
        tabBarCoordinator.start()
        
        let detailNavigationController = self.createDetailNavigationController()
        
        self.splitViewController.viewControllers = [tabBarCoordinator.toPresentable(), detailNavigationController]
                
        self.add(childCoordinator: tabBarCoordinator)
        
        self.tabBarCoordinator = tabBarCoordinator
        self.masterPresentable = tabBarCoordinator
        self.detailNavigationController = detailNavigationController
        
        self.parameters.router.setRootModule(self.splitViewController)
    }
    
    func toPresentable() -> UIViewController {        
        return self.splitViewController
    }
    
    // TODO: Do not expose publicly this method
    func restorePlaceholderDetails() {                
        // Be sure that the primary is then visible too.
        if splitViewController.displayMode == .primaryHidden {
            splitViewController.preferredDisplayMode = .allVisible
        }
        
        if splitViewController.viewControllers.count == 2 {
            let mainViewController = splitViewController.viewControllers[0]
                        
            let emptyDetailsViewController = self.createPlaceholderDetailsViewController()
            
            splitViewController.viewControllers = [mainViewController, emptyDetailsViewController]
        }

        // Release the current selected item (room/contact/group...).
        self.tabBarCoordinator?.releaseSelectedItems()
    }
    
    func popToHome(animated: Bool, completion: (() -> Void)?) {
        if let secondNavController = self.detailNavigationController {
            secondNavController.popToRootViewController(animated: animated)
        }

        // Force back to the main screen if this is not the one that is displayed
        self.tabBarCoordinator?.popToHome(animated: animated, completion: completion)
    }
    
    // MARK: - Private methods
    
    private func createPlaceholderDetailsViewController() -> UIViewController {
        return PlaceholderDetailViewController.instantiate()
    }
    
    private func createTabBarCoordinator() -> TabBarCoordinator {
        
        let coordinatorParameters = TabBarCoordinatorParameters(userSessionsService: self.parameters.userSessionsService)
        
        let tabBarCoordinator = TabBarCoordinator(parameters: coordinatorParameters)
        tabBarCoordinator.delegate = self
        return tabBarCoordinator
    }
    
    private func createDetailNavigationController() -> UINavigationController {
        let placeholderDetailViewController = self.createPlaceholderDetailsViewController()
        let detailNavigationController = RiotNavigationController(rootViewController: placeholderDetailViewController)
        return detailNavigationController
    }
}

// MARK: - UISplitViewControllerDelegate
extension SplitViewCoordinator: UISplitViewControllerDelegate {
    
    func splitViewController(_ splitViewController: UISplitViewController, separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
        
        if let detailViewController = self.masterPresentable?.secondViewControllerWhenSeparatedFromPrimary() {
            return detailViewController
        }

        // Else return the default empty details view controller from the storyboard.
        // Be sure that the primary is then visible too.
        if splitViewController.displayMode == .primaryHidden {
            splitViewController.preferredDisplayMode = .allVisible
        }
        
        return self.createPlaceholderDetailsViewController()
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        return self.masterPresentable?.collapseDetailViewController ?? false
    }
}

/// MARK: - UINavigationControllerDelegate
extension SplitViewCoordinator: TabBarCoordinatorDelegate {
    func tabBarCoordinatorDidCompleteAuthentication(_ coordinator: TabBarCoordinatorType) {
        self.delegate?.splitViewCoordinatorDidCompleteAuthentication(self)
    }
}

/// MARK: - SplitViewMasterPresentableDelegate
extension SplitViewCoordinator: SplitViewMasterPresentableDelegate {
    func splitViewMasterPresentable(_ presentable: Presentable, wantsToDisplay detailPresentable: Presentable) {
        MXLog.debug("[SplitViewCoordinator] splitViewMasterPresentable: \(presentable) wantsToDisplay detailPresentable: \(detailPresentable)")
        
        guard let detailNavigationController = self.detailNavigationController else {
            MXLog.debug("[SplitViewCoordinator] splitViewMasterPresentable: Failed to display because detailNavigationController is nil")
            return
        }
        
        detailNavigationController.viewControllers = [detailPresentable.toPresentable()]
        self.splitViewController.showDetailViewController(detailNavigationController, sender: nil)
    }
}
