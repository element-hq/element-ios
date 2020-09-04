/*
 Copyright 2018 New Vector Ltd
 
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
    
    // TODO: Move to TabBarCoordinator
    private let masterNavigationController: UINavigationController
    private let masterTabBarController: MasterTabBarController
    
    /// Completion called when `popToHomeViewControllerAnimated:` has been completed.
    private var popToHomeViewControllerCompletion: (() -> Void)?
    
    // MARK: Public
    
    var childCoordinators: [Coordinator] = []
    
    // MARK: - Setup
    
    init(router: RootRouterType, session: MXSession?) {
        self.rootRouter = router
        self.session = session
        
        // TODO: Use a dedicated stoyboard and SwiftGen to access it
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let splitViewController = storyboard.instantiateViewController(withIdentifier: "RiotSplitViewController") as? UISplitViewController else {
            fatalError("[SplitViewCoordinator] Can't load RiotSplitViewController")
        }
        splitViewController.preferredDisplayMode = .allVisible
        self.splitViewController = splitViewController
        
        guard let masterNavigationController = splitViewController.viewControllers.first as? UINavigationController else {
            fatalError("[SplitViewCoordinator] Can't load masterNavigationController")
        }
        self.masterNavigationController = masterNavigationController
        
        guard let masterTabBarController = masterNavigationController.viewControllers.first as? MasterTabBarController else {
            fatalError("[SplitViewCoordinator] Can't load masterTabBarController")
        }
        self.masterTabBarController = masterTabBarController
    }
    
    // MARK: - Public methods
    
    func start() {
        self.splitViewController.delegate = self
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
        masterTabBarController.releaseSelectedItem()
    }
    
    func popToHome(animated: Bool, completion: (() -> Void)?) {
        if let secondNavController = self.secondaryNavigationController() {
            secondNavController.popToRootViewController(animated: animated)
        }

        // Force back to the main screen if this is not the one that is displayed
        if masterTabBarController != masterNavigationController.visibleViewController {
            // Listen to the masterNavigationController changes
            // We need to be sure that masterTabBarController is back to the screen
            popToHomeViewControllerCompletion = completion
            masterNavigationController.delegate = self

            masterNavigationController.popToViewController(masterTabBarController, animated: animated)
        } else {
            // Select the Home tab
            masterTabBarController.selectedIndex = Int(TABBAR_HOME_INDEX)
            completion?()
        }
    }
    
    // MARK: - Private methods
    
    private func createPlaceholderDetailsViewController() -> UIViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let emptyDetailsViewController = storyboard.instantiateViewController(withIdentifier: "EmptyDetailsViewControllerStoryboardId")
        return emptyDetailsViewController
    }
    
    func secondaryNavigationController() -> UINavigationController? {
        guard splitViewController.viewControllers.count == 2, let secondViewController = splitViewController.viewControllers.last as? UINavigationController else {
            return nil
        }
        return secondViewController
    }
}

// MARK: - UISplitViewControllerDelegate
extension SplitViewCoordinator: UISplitViewControllerDelegate {
    
    func splitViewController(_ splitViewController: UISplitViewController, separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
                
        // Return the top view controller of the master navigation controller, if it is a navigation controller itself.
        if let topViewController = masterNavigationController.topViewController as? UINavigationController {
            // Keep the detail scene
            return topViewController
        }

        // Else return the default empty details view controller from the storyboard.
        // Be sure that the primary is then visible too.
        if splitViewController.displayMode == .primaryHidden {
            splitViewController.preferredDisplayMode = .allVisible
        }
        
        return self.createPlaceholderDetailsViewController()
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        if (masterTabBarController.currentRoomViewController == nil) && (masterTabBarController.currentContactDetailViewController == nil) && (masterTabBarController.currentGroupDetailViewController == nil) {
            // Return YES to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
            return true
        } else {
            return false
        }
    }
}

// MARK: - UINavigationControllerDelegate
extension SplitViewCoordinator: UINavigationControllerDelegate {
    
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        
        if viewController == masterTabBarController {
            masterNavigationController.delegate = nil
            
            // For unknown reason, the navigation bar is not restored correctly by [popToViewController:animated:]
            // when a ViewController has hidden it (see MXKAttachmentsViewController).
            // Patch: restore navigation bar by default here.
            masterNavigationController.isNavigationBarHidden = false

            // Release the current selected item (room/contact/...).
            masterTabBarController.releaseSelectedItem()

            if let popToHomeViewControllerCompletion = self.popToHomeViewControllerCompletion {
                let popToHomeViewControllerCompletion2: (() -> Void)? = popToHomeViewControllerCompletion
                self.popToHomeViewControllerCompletion = nil

                DispatchQueue.main.async {
                    popToHomeViewControllerCompletion2?()
                }
            }
        }
        
    }
}
