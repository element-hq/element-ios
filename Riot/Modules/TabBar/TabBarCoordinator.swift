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
    let appNavigator: AppNavigatorProtocol
    
    init(userSessionsService: UserSessionsService, appNavigator: AppNavigatorProtocol) {
        self.userSessionsService = userSessionsService
        self.appNavigator = appNavigator
    }
}

@objcMembers
final class TabBarCoordinator: NSObject, TabBarCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: TabBarCoordinatorParameters
    
    /// Completion called when `popToHomeAnimated:` has been completed.
    private var popToHomeViewControllerCompletion: (() -> Void)?
    
    // TODO: Move MasterTabBarController navigation code here
    // and if possible use a simple: `private let tabBarController: UITabBarController`
    private var masterTabBarController: MasterTabBarController!
    
    // TODO: Embed UINavigationController in each tab like recommended by Apple and remove these properties. UITabBarViewController shoud not be embed in a UINavigationController (https://github.com/vector-im/riot-ios/issues/3086).
    private let navigationRouter: NavigationRouterType
    private let masterNavigationController: UINavigationController
    
    private var currentSpaceId: String?
    private var homeViewControllerWrapperViewController: HomeViewControllerWithBannerWrapperViewController?
    
    private var currentMatrixSession: MXSession? {
        return parameters.userSessionsService.mainUserSession?.matrixSession
    }
    
    private var isTabBarControllerTopMostController: Bool {
        return self.navigationRouter.modules.last is MasterTabBarController
    }
    
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
        self.start(with: nil)
    }
        
    func start(with spaceId: String?) {
        self.currentSpaceId = spaceId
        
        // If start has been done once do setup view controllers again
        if self.masterTabBarController == nil {
            let masterTabBarController = self.createMasterTabBarController()
            masterTabBarController.masterTabBarDelegate = self
            self.masterTabBarController = masterTabBarController
            self.navigationRouter.setRootModule(masterTabBarController)
            
            // Add existing Matrix sessions if any
            for userSession in self.parameters.userSessionsService.userSessions {
                self.addMatrixSessionToMasterTabBarController(userSession.matrixSession)
            }
            
            if BuildSettings.enableSideMenu {
                self.setupSideMenuGestures()
            }
            
            self.registerUserSessionsServiceNotifications()
        }
                
        self.updateMasterTabBarController(with: spaceId)
        
        self.registerUserSessionsServiceNotifications()
        self.registerSessionChange()
        
        if let homeViewController = homeViewControllerWrapperViewController {
            let versionCheckCoordinator = VersionCheckCoordinator(rootViewController: masterTabBarController,
                                                              bannerPresenter: homeViewController,
                                                              themeService: ThemeService.shared())
            versionCheckCoordinator.start()
            add(childCoordinator: versionCheckCoordinator)
        }
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
            
            let didPopToHome: (() -> Void) = {
                
                // For unknown reason, the navigation bar is not restored correctly by [popToViewController:animated:]
                // when a ViewController has hidden it (see MXKAttachmentsViewController).
                // Patch: restore navigation bar by default here.
                self.masterNavigationController.isNavigationBarHidden = false

                // Release the current selected item (room/contact/...).
                self.masterTabBarController.releaseSelectedItem()
                
                // Select home tab
                self.masterTabBarController.selectTab(at: .home)
                
                completion?()
            }

            // If MasterTabBarController is not visible because there is a modal above it
            // but still the top view controller of navigation controller
            if self.isTabBarControllerTopMostController {
                didPopToHome()
            } else {
                // Otherwise MasterTabBarController is not the top controller of the navigation controller
                
                // Waiting for `self.navigationRouter` popping to MasterTabBarController
                var token: NSObjectProtocol?
                token = NotificationCenter.default.addObserver(forName: NavigationRouter.didPopViewController, object: self.navigationRouter, queue: OperationQueue.main) { [weak self] (notification) in
                    
                    guard let self = self else {
                        return
                    }
                    
                    // If MasterTabBarController is now the top most controller in navigation controller stack call the completion
                    if self.isTabBarControllerTopMostController {
                        
                        didPopToHome()
                        
                        if let token = token {
                            NotificationCenter.default.removeObserver(token)
                        }
                    }
                }
                
                // Pop to root view controller
                self.navigationRouter.popToRootModule(animated: animated)
            }
        } else {
            // Tab bar controller is already visible
            // Select the Home tab
            masterTabBarController.selectTab(at: .home)
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
        
        if BuildSettings.enableSideMenu {
            let sideMenuBarButtonItem: MXKBarButtonItem = MXKBarButtonItem(image: Asset.Images.sideMenuIcon.image, style: .plain) { [weak self] in
                self?.showSideMenu()
            }
            sideMenuBarButtonItem.accessibilityLabel = VectorL10n.sideMenuRevealActionAccessibilityLabel
            
            tabBarController.navigationItem.leftBarButtonItem = sideMenuBarButtonItem
        } else {
            let settingsBarButtonItem: MXKBarButtonItem = MXKBarButtonItem(image: Asset.Images.settingsIcon.image, style: .plain) { [weak self] in
                self?.showSettings()
            }
            settingsBarButtonItem.accessibilityLabel = VectorL10n.settingsTitle
            
            tabBarController.navigationItem.leftBarButtonItem = settingsBarButtonItem
        }
        
        let searchBarButtonItem: MXKBarButtonItem = MXKBarButtonItem(image: Asset.Images.searchIcon.image, style: .plain) { [weak self] in
            self?.showUnifiedSearch()
        }
        searchBarButtonItem.accessibilityLabel = VectorL10n.searchDefaultPlaceholder
        
        tabBarController.navigationItem.rightBarButtonItem = searchBarButtonItem
        
        self.updateTabControllers(for: tabBarController, showCommunities: true)
        
        return tabBarController
    }
    
    private func createHomeViewController() -> UIViewController {
        let homeViewController: HomeViewController = HomeViewController.instantiate()
        homeViewController.tabBarItem.tag = Int(TABBAR_HOME_INDEX)
        homeViewController.tabBarItem.image = homeViewController.tabBarItem.image
        homeViewController.accessibilityLabel = VectorL10n.titleHome
        
        let wrapperViewController = HomeViewControllerWithBannerWrapperViewController(viewController: homeViewController)
        homeViewControllerWrapperViewController = wrapperViewController
        return wrapperViewController
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
    
    private func setupSideMenuGestures() {
        let gesture = self.parameters.appNavigator.sideMenu.addScreenEdgePanGesturesToPresent(to: masterTabBarController.view)
        gesture.delegate = self
    }
    
    private func updateMasterTabBarController(with spaceId: String?) {
                
        self.updateTabControllers(for: self.masterTabBarController, showCommunities: spaceId == nil)
        self.masterTabBarController.filterRooms(withParentId: spaceId, inMatrixSession: self.currentMatrixSession)
    }
    
    private func updateTabControllers(for tabBarController: MasterTabBarController, showCommunities: Bool) {
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
        
        if RiotSettings.shared.homeScreenShowCommunitiesTab && !(self.currentMatrixSession?.groups().isEmpty ?? false) && showCommunities {
            let groupsViewController = self.createGroupsViewController()
            viewControllers.append(groupsViewController)
        }
        
        tabBarController.updateViewControllers(viewControllers)
    }
    
    // MARK: Navigation
    
    private func showSideMenu() {
        self.parameters.appNavigator.sideMenu.show(from: self.masterTabBarController, animated: true)
    }
    
    private func dismissSideMenu(animated: Bool) {
        self.parameters.appNavigator.sideMenu.dismiss(animated: animated)
    }
    
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
        
        if let matrixSession = self.currentMatrixSession, matrixSession.groups().isEmpty {
            self.masterTabBarController.removeTab(at: .groups)
        }
    }
    
    @objc private func userSessionsServiceWillRemoveUserSession(_ notification: Notification) {
        guard let userSession = notification.userInfo?[UserSessionsService.NotificationUserInfoKey.userSession] as? UserSession else {
            return
        }
        
        self.removeMatrixSessionFromMasterTabBarController(userSession.matrixSession)
    }
    
    // TODO: Remove Matrix session handling from the view controller
    private func addMatrixSessionToMasterTabBarController(_ matrixSession: MXSession) {
        MXLog.debug("[TabBarCoordinator] masterTabBarController.addMatrixSession")
        self.masterTabBarController.addMatrixSession(matrixSession)
    }
    
    // TODO: Remove Matrix session handling from the view controller
    private func removeMatrixSessionFromMasterTabBarController(_ matrixSession: MXSession) {
        MXLog.debug("[TabBarCoordinator] masterTabBarController.removeMatrixSession")
        self.masterTabBarController.removeMatrixSession(matrixSession)
    }
    
    private func registerSessionChange() {
        NotificationCenter.default.addObserver(self, selector: #selector(sessionDidSync(_:)), name: NSNotification.Name.mxSessionDidSync, object: nil)
    }
    
    @objc private func sessionDidSync(_ notification: Notification) {
        if self.currentMatrixSession?.groups().isEmpty ?? true {
            self.masterTabBarController.removeTab(at: .groups)
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
    
    func masterTabBarController(_ masterTabBarController: MasterTabBarController!, needsSideMenuIconWithNotification displayNotification: Bool) {
        let image = displayNotification ? Asset.Images.sideMenuNotifIcon.image : Asset.Images.sideMenuIcon.image
        let sideMenuBarButtonItem: MXKBarButtonItem = MXKBarButtonItem(image: image, style: .plain) { [weak self] in
            self?.showSideMenu()
        }
        sideMenuBarButtonItem.accessibilityLabel = VectorL10n.sideMenuRevealActionAccessibilityLabel
        
        self.masterTabBarController.navigationItem.leftBarButtonItem = sideMenuBarButtonItem
    }
}

// MARK: - UIGestureRecognizerDelegate

/**
 Prevent the side menu gesture from clashing with other gestures like the home screen horizontal scroll views.
 Also make sure that it doesn't cancel out UINavigationController backwards swiping
 */
extension TabBarCoordinator: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if otherGestureRecognizer.isKind(of: UIScreenEdgePanGestureRecognizer.self) {
            return false
        } else {
            return true
        }
    }
}
