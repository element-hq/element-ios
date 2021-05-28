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

/// TabBarCoordinator input parameters
class TabBarCoordinatorParameters {
    
    let userSessionsService: UserSessionsService
    
    init(userSessionsService: UserSessionsService) {
        self.userSessionsService = userSessionsService
    }
}

@objcMembers
final class TabBarCoordinator: NSObject, TabBarCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    let parameters: TabBarCoordinatorParameters
    
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
        
    init(parameters: TabBarCoordinatorParameters) {
        self.parameters = parameters
        
        let masterNavigationController = RiotNavigationController()
        self.navigationRouter = NavigationRouter(navigationController: masterNavigationController)
        self.masterNavigationController = masterNavigationController
    }    
    
    // MARK: - Public methods
    
    func start() {
        let masterTabBarController = self.createMasterTabBarController()
        masterTabBarController.masterTabBarDelegate = self
        self.masterTabBarController = masterTabBarController
        self.navigationRouter.setRootModule(masterTabBarController)
        
        // Add existing Matrix sessions if any
        for userSession in self.parameters.userSessionsService.userSessions {
            self.addMatrixSessionToMasterTabBarController(userSession.matrixSession)
        }
        
        self.registerUserSessionsServiceNotifications()
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
        let tabBarController = MasterTabBarController()
        
        let settingsBarButtonItem: MXKBarButtonItem = MXKBarButtonItem(image: Asset.Images.settingsIcon.image, style: .plain) { [weak self] in
            self?.showSettings()
        }
        settingsBarButtonItem.accessibilityLabel = VectorL10n.settingsTitle
        
        tabBarController.navigationItem.leftBarButtonItem = settingsBarButtonItem
        
        let searchBarButtonItem: MXKBarButtonItem = MXKBarButtonItem(image: Asset.Images.searchIcon.image, style: .plain) { [weak self] in
            self?.showUnifiedSearch()
        }
        searchBarButtonItem.accessibilityLabel = VectorL10n.searchDefaultPlaceholder
        
        tabBarController.navigationItem.rightBarButtonItem = searchBarButtonItem
        
        var viewControllers: [UIViewController] = []
                
        let homeViewController = self.createHomeViewController()
        viewControllers.append(homeViewController)
        
        if RiotSettings.shared.homeScreenShowFavouritesTab {
            let favouritesViewController = self.createFavouritesViewController()
            viewControllers.append(favouritesViewController)
        }
        
        if RiotSettings.shared.homeScreenShowPeopleTab {
            let peopleViewController = self.createPeopleViewController()
            viewControllers.append(peopleViewController)
        }
        
        if RiotSettings.shared.homeScreenShowRoomsTab {
            let roomsViewController = self.createRoomsViewController()
            viewControllers.append(roomsViewController)
        }
        
        if RiotSettings.shared.homeScreenShowCommunitiesTab {
            let groupsViewController = self.createGroupsViewController()
            viewControllers.append(groupsViewController)
        }
        
        tabBarController.updateViewControllers(viewControllers)
        
        return tabBarController
    }
    
    private func createHomeViewController() -> HomeViewController {
        let homeViewController: HomeViewController = HomeViewController.instantiate()
        homeViewController.tabBarItem.tag = Int(TABBAR_HOME_INDEX)
        homeViewController.accessibilityLabel = VectorL10n.titleHome
        return homeViewController
    }
    
    private func createFavouritesViewController() -> FavouritesViewController {
        let favouritesViewController: FavouritesViewController = FavouritesViewController.instantiate()
        favouritesViewController.tabBarItem.tag = Int(TABBAR_FAVOURITES_INDEX)
        favouritesViewController.accessibilityLabel = VectorL10n.titleFavourites
        return favouritesViewController
    }
    
    private func createPeopleViewController() -> PeopleViewController {
        let peopleViewController: PeopleViewController = PeopleViewController.instantiate()
        peopleViewController.tabBarItem.tag = Int(TABBAR_PEOPLE_INDEX)
        peopleViewController.accessibilityLabel = VectorL10n.titlePeople
        return peopleViewController
    }
    
    private func createRoomsViewController() -> RoomsViewController {
        let roomsViewController: RoomsViewController = RoomsViewController.instantiate()
        roomsViewController.tabBarItem.tag = Int(TABBAR_ROOMS_INDEX)
        roomsViewController.accessibilityLabel = VectorL10n.titleRooms
        return roomsViewController
    }
    
    private func createGroupsViewController() -> GroupsViewController {
        let groupsViewController: GroupsViewController = GroupsViewController.instantiate()
        groupsViewController.tabBarItem.tag = Int(TABBAR_GROUPS_INDEX)
        groupsViewController.accessibilityLabel = VectorL10n.titleGroups
        return groupsViewController
    }
    
    private func createUnifiedSearchController() -> UnifiedSearchViewController {
        
        let viewController: UnifiedSearchViewController = UnifiedSearchViewController.instantiate()
        viewController.loadViewIfNeeded()
        
        for userSession in self.parameters.userSessionsService.userSessions {
            viewController.addMatrixSession(userSession.matrixSession)
        }
        
        return viewController
    }
    
    private func createSettingsViewController() -> SettingsViewController {
        let viewController: SettingsViewController = SettingsViewController.instantiate()
        viewController.loadViewIfNeeded()
        return viewController
    }
    
    // MARK: Navigation
    
    // FIXME: Should be displayed per tab.
    private func showSettings() {
        let viewController = self.createSettingsViewController()
        
        self.navigationRouter.push(viewController, animated: true, popCompletion: nil)
    }
    
    // FIXME: Should be displayed per tab.
    private func showUnifiedSearch() {
        let viewController = self.createUnifiedSearchController()
        
        self.masterTabBarController.unifiedSearchViewController = viewController
        self.navigationRouter.push(viewController, animated: true, popCompletion: nil)
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
    
    // MARK: UserSessions management
    
    private func registerUserSessionsServiceNotifications() {
        
        // Listen only notifications from the current UserSessionsService instance
        let userSessionService = self.parameters.userSessionsService
        
        NotificationCenter.default.addObserver(self, selector: #selector(userSessionsServiceDidAddUserSession(_:)), name: UserSessionsService.didAddUserSession, object: userSessionService)
        
        NotificationCenter.default.addObserver(self, selector: #selector(userSessionsServiceWillRemoveUserSession(_:)), name: UserSessionsService.willRemoveUserSession, object: userSessionService)
    }
    
    @objc private func userSessionsServiceDidAddUserSession(_ notification: Notification) {
        guard let userSession = notification.userInfo?[UserSessionsService.NotificationUserInfoKey.userSession] as? UserSession else {
            return
        }
        
        self.addMatrixSessionToMasterTabBarController(userSession.matrixSession)
    }
    
    @objc private func userSessionsServiceWillRemoveUserSession(_ notification: Notification) {
        guard let userSession = notification.userInfo?[UserSessionsService.NotificationUserInfoKey.userSession] as? UserSession else {
            return
        }
        
        self.removeMatrixSessionFromMasterTabBarController(userSession.matrixSession)
    }
    
    // TODO: Remove Matrix session handling from the view controller
    private func addMatrixSessionToMasterTabBarController(_ matrixSession: MXSession) {
        guard self.masterTabBarController.mxSessions.contains(matrixSession) == false else {
            return
        }
        NSLog("[TabBarCoordinator] masterTabBarController.addMatrixSession")
        self.masterTabBarController.addMatrixSession(matrixSession)
    }
    
    // TODO: Remove Matrix session handling from the view controller
    private func removeMatrixSessionFromMasterTabBarController(_ matrixSession: MXSession) {
        guard self.masterTabBarController.mxSessions.contains(matrixSession) else {
            return
        }
        NSLog("[TabBarCoordinator] masterTabBarController.removeMatrixSession")
        self.masterTabBarController.removeMatrixSession(matrixSession)
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
