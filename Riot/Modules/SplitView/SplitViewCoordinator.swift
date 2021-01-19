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

final class SplitViewCoordinator: NSObject, SplitViewCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let rootRouter: RootRouterType
    private var session: MXSession?
    
    private let splitViewController: UISplitViewController
    
    private weak var masterPresentable: SplitViewMasterPresentable?
    private var detailNavigationController: UINavigationController?
    
    private weak var tabBarCoordinator: TabBarCoordinatorType?
    
    // MARK: Public
    
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: SplitViewCoordinatorDelegate?
    
    // MARK: - Setup
    
    // TODO: Improve sessions injection
    // at the moment the session is not used, see TabBarCoordinator `init`.
    init(router: RootRouterType, session: MXSession?) {
        self.rootRouter = router
        self.session = session
        
        let splitViewController = UISplitViewController()
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
        
        self.rootRouter.setRootModule(self.splitViewController)
    }
    
    func update(with session: MXSession) {
        self.session = session
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
        let tabBarCoordinator = TabBarCoordinator(session: self.session)
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
        NSLog("[SplitViewCoordinator] splitViewMasterPresentable: \(presentable) wantsToDisplay detailPresentable: \(detailPresentable)")
        
        guard let detailNavigationController = self.detailNavigationController else {
            NSLog("[SplitViewCoordinator] splitViewMasterPresentable: Failed to display because detailNavigationController is nil")
            return
        }
        
        detailNavigationController.viewControllers = [detailPresentable.toPresentable()]
        self.splitViewController.showDetailViewController(detailNavigationController, sender: nil)
    }
}
