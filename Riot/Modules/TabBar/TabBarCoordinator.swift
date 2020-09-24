// File created from FlowTemplate
// $ createRootCoordinator.sh TabBar TabBar
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

import UIKit

@objcMembers
final class TabBarCoordinator: NSObject, TabBarCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
        
    private var session: MXSession?
    
    /// Completion called when `popToHomeAnimated:` has been completed.
    private var popToHomeViewControllerCompletion: (() -> Void)?
    
    // TODO: Move MasterTabBarController navigation code here
    // and if possible use a simple: `private let tabBarController: UITabBarController`
    private var masterTabBarController: MasterTabBarController!
    
    // TODO: Embed UINavigationController in each tab like recommended by Apple and remove these properties. UITabBarViewController shoud not be embed in a UINavigationController (https://github.com/vector-im/riot-ios/issues/3086).
    private let navigationRouter: NavigationRouterType
    private let masterNavigationController: UINavigationController
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: TabBarCoordinatorDelegate?
    
    weak var splitViewMasterPresentableDelegate: SplitViewMasterPresentableDelegate?
    
    // MARK: - Setup
    
    // TODO: Improve sessions injection
    // at the moment Matrix session is injected to MasterTabBarController via LegacyAppDelegate
    init(session: MXSession?) {
        let masterNavigationController = RiotNavigationController()
        self.navigationRouter = NavigationRouter(navigationController: masterNavigationController)
        self.masterNavigationController = masterNavigationController
        self.session = session
    }    
    
    // MARK: - Public methods
    
    func start() {
        let masterTabBarController = self.createMasterTabBarController()
        masterTabBarController.masterTabBarDelegate = self
        self.masterTabBarController = masterTabBarController
        self.navigationRouter.setRootModule(masterTabBarController)
      }
    
    func toPresentable() -> UIViewController {
        return self.navigationRouter.toPresentable()
    }
    
    func releaseSelectedItems() {
        self.masterTabBarController.releaseSelectedItem()
    }
    
    func popToHome(animated: Bool, completion: (() -> Void)?) {
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
    
    // MARK: - SplitViewMasterPresentable
    
    var collapseDetailViewController: Bool {
        if (masterTabBarController.currentRoomViewController == nil) && (masterTabBarController.currentContactDetailViewController == nil) && (masterTabBarController.currentGroupDetailViewController == nil) {
            // Return YES to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
            return true
        } else {
            return false
        }
    }
    
    func secondViewControllerWhenSeparatedFromPrimary() -> UIViewController? {
        // Return the top view controller of the master navigation controller, if it is a navigation controller itself.
        if let topViewController = masterNavigationController.topViewController as? UINavigationController {
            // Keep the detail scene
            return topViewController
        }
        return nil
    }
    
    // MARK: - Private methods
    
    private func createMasterTabBarController() -> MasterTabBarController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let masterTabBarController = storyboard.instantiateViewController(withIdentifier: "MasterTabBarController") as? MasterTabBarController else {
            fatalError("[TabBarCoordinator] Can't load MasterTabBarController")
        }
        return masterTabBarController
    }
    
    // MARK: Navigation
    
    // FIXME: Should be displayed per tab.
    private func showSettings() {
        // TODO: Implement
    }
    
    // FIXME: Should be displayed per tab.
    private func showUnifiedSearch() {
        // TODO: Implement
    }
    
    // FIXME: Should be displayed from a tab.
    private func showContactDetails() {
        // TODO: Implement
    }
    
    // FIXME: Should be displayed from a tab.
    private func showRoomDetails() {
        // TODO: Implement
    }
    
    // FIXME: Should be displayed from a tab.
    private func showGroupDetails() {
        // TODO: Implement
    }
}

// MARK: - UINavigationControllerDelegate
extension TabBarCoordinator: UINavigationControllerDelegate {
    
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

// MARK: - MasterTabBarControllerDelegate
extension TabBarCoordinator: MasterTabBarControllerDelegate {
    
    func masterTabBarControllerDidCompleteAuthentication(_ masterTabBarController: MasterTabBarController!) {
        self.delegate?.tabBarCoordinatorDidCompleteAuthentication(self)
    }
    
    func masterTabBarController(_ masterTabBarController: MasterTabBarController!, wantsToDisplayDetailViewController detailViewController: UIViewController!) {
        
        self.splitViewMasterPresentableDelegate?.splitViewMasterPresentable(self, wantsToDisplay: detailViewController)
    }
}
