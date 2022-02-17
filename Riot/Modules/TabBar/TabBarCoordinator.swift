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
    
    private let parameters: TabBarCoordinatorParameters
    private let activityIndicatorPresenter: ActivityIndicatorPresenterType
    
    // Indicate if the Coordinator has started once
    private var hasStartedOnce: Bool {
        return self.masterTabBarController != nil
    }
    
    // TODO: Move MasterTabBarController navigation code here
    // and if possible use a simple: `private let tabBarController: UITabBarController`
    private var masterTabBarController: MasterTabBarController!
    
    // TODO: Embed UINavigationController in each tab like recommended by Apple and remove these properties. UITabBarViewController shoud not be embed in a UINavigationController (https://github.com/vector-im/riot-ios/issues/3086).
    private let navigationRouter: NavigationRouterType
    private let masterNavigationController: UINavigationController
    
    private var currentSpaceId: String?
    
    private weak var versionCheckCoordinator: VersionCheckCoordinator?
    
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
        self.activityIndicatorPresenter = ActivityIndicatorPresenter()
    }
    
    // MARK: - Public methods
    
    func start() {
        self.start(with: nil)
    }
        
    func start(with spaceId: String?) {
                
        // If start has been done once do not setup view controllers again
        if self.hasStartedOnce == false {
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
            self.registerSessionChange()
            
            self.updateMasterTabBarController(with: spaceId, forceReload: true)
        } else {            
            self.updateMasterTabBarController(with: spaceId)
        }
        
        self.currentSpaceId = spaceId
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
                token = NotificationCenter.default.addObserver(forName: NavigationRouter.didPopModule, object: self.navigationRouter, queue: OperationQueue.main) { [weak self] (notification) in
                    
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
    
    var selectedNavigationRouter: NavigationRouterType? {
        return self.navigationRouter
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
        
        return tabBarController
    }
    
    private func createVersionCheckCoordinator(withRootViewController rootViewController: UIViewController, bannerPresentrer: BannerPresentationProtocol) -> VersionCheckCoordinator {
        let versionCheckCoordinator = VersionCheckCoordinator(rootViewController: rootViewController,
                                                              bannerPresenter: bannerPresentrer,
                                                              themeService: ThemeService.shared()) 
        return versionCheckCoordinator
    }
    
    private func createHomeViewController() -> HomeViewControllerWithBannerWrapperViewController {
        let homeViewController: HomeViewController = HomeViewController.instantiate()
        homeViewController.tabBarItem.tag = Int(TABBAR_HOME_INDEX)
        homeViewController.tabBarItem.image = homeViewController.tabBarItem.image
        homeViewController.accessibilityLabel = VectorL10n.titleHome
        
        if BuildSettings.appActivityIndicators {
            homeViewController.activityPresenter = AppActivityIndicatorPresenter(appNavigator: parameters.appNavigator)
        }
        
        let wrapperViewController = HomeViewControllerWithBannerWrapperViewController(viewController: homeViewController)        
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
    
    private func updateMasterTabBarController(with spaceId: String?, forceReload: Bool = false) {
        
        guard forceReload || spaceId != self.currentSpaceId else { return }
                
        self.updateTabControllers(for: self.masterTabBarController, showCommunities: spaceId == nil)
        self.masterTabBarController.filterRooms(withParentId: spaceId, inMatrixSession: self.currentMatrixSession)
    }
    
    // TODO: Avoid to reinstantiate controllers everytime
    private func updateTabControllers(for tabBarController: MasterTabBarController, showCommunities: Bool) {
        var viewControllers: [UIViewController] = []
          
        let homeViewController = self.createHomeViewController()
        
        viewControllers.append(homeViewController)
        
        if let existingVersionCheckCoordinator = self.versionCheckCoordinator {
            self.remove(childCoordinator: existingVersionCheckCoordinator)
        }
        
        if let masterTabBarController = self.masterTabBarController {
            
            let versionCheckCoordinator = self.createVersionCheckCoordinator(withRootViewController: masterTabBarController, bannerPresentrer: homeViewController)
            versionCheckCoordinator.start()
            self.add(childCoordinator: versionCheckCoordinator)
            
            self.versionCheckCoordinator = versionCheckCoordinator
        }
        
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
        
        self.navigationRouter.push(viewController, animated: true, popCompletion: nil)
    }
    
    // FIXME: Should be displayed from a tab.
    private func showContactDetails(with contact: MXKContact, presentationParameters: ScreenPresentationParameters) {
        
        let coordinatorParameters = ContactDetailsCoordinatorParameters(contact: contact)
        let coordinator = ContactDetailsCoordinator(parameters: coordinatorParameters)
        coordinator.start()
        self.add(childCoordinator: coordinator)
        
        self.showSplitViewDetails(with: coordinator, stackedOnSplitViewDetail: presentationParameters.stackAboveVisibleViews) { [weak self] in
            self?.remove(childCoordinator: coordinator)
        }
    }
    
    // FIXME: Should be displayed from a tab.
    private func showGroupDetails(with group: MXGroup, for matrixSession: MXSession, presentationParameters: ScreenPresentationParameters) {
        let coordinatorParameters = GroupDetailsCoordinatorParameters(session: matrixSession, group: group)
        let coordinator = GroupDetailsCoordinator(parameters: coordinatorParameters)
        coordinator.start()
        self.add(childCoordinator: coordinator)
        
        self.showSplitViewDetails(with: coordinator, stackedOnSplitViewDetail: presentationParameters.stackAboveVisibleViews) { [weak self] in
            self?.remove(childCoordinator: coordinator)
        }
    }
    
    private func showRoom(withId roomId: String, eventId: String? = nil) {
        
        guard let matrixSession = self.parameters.userSessionsService.mainUserSession?.matrixSession else {
            return
        }
        
        self.showRoom(with: roomId, eventId: eventId, matrixSession: matrixSession)
    }
    
    private func showRoom(withNavigationParameters roomNavigationParameters: RoomNavigationParameters, completion: (() -> Void)?) {
        
        if let threadParameters = roomNavigationParameters.threadParameters, threadParameters.stackRoomScreen {
            showRoomAndThread(with: roomNavigationParameters,
                              completion: completion)
        } else {
            let threadId = roomNavigationParameters.threadParameters?.threadId
            let displayConfig: RoomDisplayConfiguration
            if threadId != nil {
                displayConfig = .forThreads
            } else {
                displayConfig = .default
            }
            let roomCoordinatorParameters = RoomCoordinatorParameters(navigationRouterStore: NavigationRouterStore.shared,
                                                                      session: roomNavigationParameters.mxSession,
                                                                      roomId: roomNavigationParameters.roomId,
                                                                      eventId: roomNavigationParameters.eventId,
                                                                      threadId: threadId,
                                                                      displayConfiguration: displayConfig)
            
            self.showRoom(with: roomCoordinatorParameters,
                          stackOnSplitViewDetail: roomNavigationParameters.presentationParameters.stackAboveVisibleViews,
                          completion: completion)
        }
    }
        
    private func showRoom(with roomId: String, eventId: String?, matrixSession: MXSession, completion: (() -> Void)? = nil) {
        
        // RoomCoordinator will be presented by the split view.
        // As we don't know which navigation controller instance will be used,
        // give the NavigationRouterStore instance and let it find the associated navigation controller
        let roomCoordinatorParameters = RoomCoordinatorParameters(navigationRouterStore: NavigationRouterStore.shared, session: matrixSession, roomId: roomId, eventId: eventId)
        
        self.showRoom(with: roomCoordinatorParameters, completion: completion)
    }
    
    private func showRoomPreview(with previewData: RoomPreviewData) {
                
        // RoomCoordinator will be presented by the split view
        // We don't which navigation controller instance will be used
        // Give the NavigationRouterStore instance and let it find the associated navigation controller if needed
        let roomCoordinatorParameters = RoomCoordinatorParameters(navigationRouterStore: NavigationRouterStore.shared, previewData: previewData)
        
        self.showRoom(with: roomCoordinatorParameters)
    }
    
    private func showRoomPreview(withNavigationParameters roomPreviewNavigationParameters: RoomPreviewNavigationParameters, completion: (() -> Void)?) {
        
        let roomCoordinatorParameters = RoomCoordinatorParameters(navigationRouterStore: NavigationRouterStore.shared,
                                                                  previewData: roomPreviewNavigationParameters.previewData)
        
        self.showRoom(with: roomCoordinatorParameters,
                      stackOnSplitViewDetail: roomPreviewNavigationParameters.presentationParameters.stackAboveVisibleViews,
                      completion: completion)
    }
    
    private func showRoom(with parameters: RoomCoordinatorParameters,
                          stackOnSplitViewDetail: Bool = false,
                          completion: (() -> Void)? = nil) {
        
        //  try to find the desired room screen in the stack
        if let roomCoordinator = self.splitViewMasterPresentableDelegate?.detailModules.last(where: { presentable in
            guard let roomCoordinator = presentable as? RoomCoordinatorProtocol else {
                return false
            }
            return roomCoordinator.roomId == parameters.roomId
                && roomCoordinator.threadId == parameters.threadId
                && roomCoordinator.mxSession == parameters.session
        }) as? RoomCoordinatorProtocol {
            self.splitViewMasterPresentableDelegate?.splitViewMasterPresentable(self, wantsToPopTo: roomCoordinator)
            //  go to a specific event if provided
            if let eventId = parameters.eventId {
                roomCoordinator.start(withEventId: eventId, completion: completion)
            } else {
                completion?()
            }
            return
        }
                        
        let coordinator = RoomCoordinator(parameters: parameters)
        coordinator.delegate = self
        coordinator.start(withCompletion: completion)
        self.add(childCoordinator: coordinator)
        
        self.showSplitViewDetails(with: coordinator, stackedOnSplitViewDetail: stackOnSplitViewDetail) { [weak self] in
            // NOTE: The RoomDataSource releasing is handled in SplitViewCoordinator
            self?.remove(childCoordinator: coordinator)
        }
    }

    private func showRoomAndThread(with roomNavigationParameters: RoomNavigationParameters,
                                   completion: (() -> Void)? = nil) {
        self.activityIndicatorPresenter.presentActivityIndicator(on: toPresentable().view, animated: false)
        let dispatchGroup = DispatchGroup()

        //  create room coordinator
        let roomCoordinatorParameters = RoomCoordinatorParameters(navigationRouterStore: NavigationRouterStore.shared,
                                                                  session: roomNavigationParameters.mxSession,
                                                                  roomId: roomNavigationParameters.roomId,
                                                                  eventId: nil,
                                                                  threadId: nil)

        dispatchGroup.enter()
        let roomCoordinator = RoomCoordinator(parameters: roomCoordinatorParameters)
        roomCoordinator.delegate = self
        roomCoordinator.start {
            dispatchGroup.leave()
        }
        self.add(childCoordinator: roomCoordinator)

        //  create thread coordinator
        let threadCoordinatorParameters = RoomCoordinatorParameters(navigationRouterStore: NavigationRouterStore.shared,
                                                                    session: roomNavigationParameters.mxSession,
                                                                    roomId: roomNavigationParameters.roomId,
                                                                    eventId: roomNavigationParameters.eventId,
                                                                    threadId: roomNavigationParameters.threadParameters?.threadId,
                                                                    displayConfiguration: .forThreads)

        dispatchGroup.enter()
        let threadCoordinator = RoomCoordinator(parameters: threadCoordinatorParameters)
        threadCoordinator.delegate = self
        threadCoordinator.start {
            dispatchGroup.leave()
        }
        self.add(childCoordinator: threadCoordinator)

        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            let modules: [NavigationModule] = [
                NavigationModule(presentable: roomCoordinator, popCompletion: { [weak self] in
                    // NOTE: The RoomDataSource releasing is handled in SplitViewCoordinator
                    self?.remove(childCoordinator: roomCoordinator)
                }),
                NavigationModule(presentable: threadCoordinator, popCompletion: { [weak self] in
                    // NOTE: The RoomDataSource releasing is handled in SplitViewCoordinator
                    self?.remove(childCoordinator: threadCoordinator)
                })
            ]

            self.showSplitViewDetails(with: modules,
                                      stack: roomNavigationParameters.presentationParameters.stackAboveVisibleViews)

            self.activityIndicatorPresenter.removeCurrentActivityIndicator(animated: true)
        }
    }
    
    // MARK: Split view
    
    /// If the split view is collapsed (one column visible) it will push the Presentable on the primary navigation controller, otherwise it will show the Presentable as the secondary view of the split view.
    private func replaceSplitViewDetails(with presentable: Presentable, popCompletion: (() -> Void)? = nil) {
        self.splitViewMasterPresentableDelegate?.splitViewMasterPresentable(self, wantsToReplaceDetailWith: presentable, popCompletion: popCompletion)
    }
    
    /// If the split view is collapsed (one column visible) it will push the Presentable on the primary navigation controller, otherwise it will show the Presentable as the secondary view of the split view on top of existing views.
    private func stackSplitViewDetails(with presentable: Presentable, popCompletion: (() -> Void)? = nil) {
        self.splitViewMasterPresentableDelegate?.splitViewMasterPresentable(self, wantsToStack: presentable, popCompletion: popCompletion)
    }
    
    private func showSplitViewDetails(with presentable: Presentable, stackedOnSplitViewDetail: Bool, popCompletion: (() -> Void)? = nil) {
        
        if stackedOnSplitViewDetail {
            self.stackSplitViewDetails(with: presentable, popCompletion: popCompletion)
        } else {
            self.replaceSplitViewDetails(with: presentable, popCompletion: popCompletion)
        }
    }
    
    private func showSplitViewDetails(with modules: [NavigationModule], stack: Bool) {
        if stack {
            self.splitViewMasterPresentableDelegate?.splitViewMasterPresentable(self, wantsToStack: modules)
        } else {
            self.splitViewMasterPresentableDelegate?.splitViewMasterPresentable(self, wantsToReplaceDetailsWith: modules)
        }
    }
    
    private func resetSplitViewDetails() {
        self.splitViewMasterPresentableDelegate?.splitViewMasterPresentableWantsToResetDetail(self)
    }
    
    @available(iOS 14.0, *)
    private func presentAnalyticsPrompt(with session: MXSession) {
        let parameters = AnalyticsPromptCoordinatorParameters(session: session)
        let coordinator = AnalyticsPromptCoordinator(parameters: parameters)
        
        coordinator.completion = { [weak self, weak coordinator] in
            guard let self = self, let coordinator = coordinator else { return }
            
            self.navigationRouter.dismissModule(animated: true, completion: nil)
            self.remove(childCoordinator: coordinator)
        }
        
        add(childCoordinator: coordinator)
        
        navigationRouter.present(coordinator, animated: true)
        coordinator.start()
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
       
    func masterTabBarController(_ masterTabBarController: MasterTabBarController!, didSelectRoomWith roomNavigationParameters: RoomNavigationParameters!, completion: (() -> Void)!) {
        self.showRoom(withNavigationParameters: roomNavigationParameters, completion: completion)
    }
    
    func masterTabBarController(_ masterTabBarController: MasterTabBarController!, didSelectRoomPreviewWith roomPreviewScreenParameters: RoomPreviewNavigationParameters!, completion: (() -> Void)!) {
        self.showRoomPreview(withNavigationParameters: roomPreviewScreenParameters, completion: completion)
    }
    
    func masterTabBarController(_ masterTabBarController: MasterTabBarController!, didSelect contact: MXKContact!, with presentationParameters: ScreenPresentationParameters!) {
        self.showContactDetails(with: contact, presentationParameters: presentationParameters)
    }
        
    func masterTabBarControllerDidCompleteAuthentication(_ masterTabBarController: MasterTabBarController!) {
        self.delegate?.tabBarCoordinatorDidCompleteAuthentication(self)
    }
    
    func masterTabBarController(_ masterTabBarController: MasterTabBarController!, didSelectRoomWithId roomId: String!, andEventId eventId: String!, inMatrixSession matrixSession: MXSession!, completion: (() -> Void)!) {
        self.showRoom(with: roomId, eventId: eventId, matrixSession: matrixSession, completion: completion)
    }
    
    func masterTabBarController(_ masterTabBarController: MasterTabBarController!, didSelect group: MXGroup!, inMatrixSession matrixSession: MXSession!, presentationParameters: ScreenPresentationParameters!) {
        self.showGroupDetails(with: group, for: matrixSession, presentationParameters: presentationParameters)
    }
    
    func masterTabBarController(_ masterTabBarController: MasterTabBarController!, needsSideMenuIconWithNotification displayNotification: Bool) {
        let image = displayNotification ? Asset.Images.sideMenuNotifIcon.image : Asset.Images.sideMenuIcon.image
        let sideMenuBarButtonItem: MXKBarButtonItem = MXKBarButtonItem(image: image, style: .plain) { [weak self] in
            self?.showSideMenu()
        }
        sideMenuBarButtonItem.accessibilityLabel = VectorL10n.sideMenuRevealActionAccessibilityLabel
        
        self.masterTabBarController.navigationItem.leftBarButtonItem = sideMenuBarButtonItem
    }
    
    func masterTabBarController(_ masterTabBarController: MasterTabBarController!, shouldPresentAnalyticsPromptForMatrixSession matrixSession: MXSession!) {
        if #available(iOS 14.0, *) {
            presentAnalyticsPrompt(with: matrixSession)
        }
    }
}

// MARK: - RoomCoordinatorDelegate
extension TabBarCoordinator: RoomCoordinatorDelegate {
    
    func roomCoordinatorDidDismissInteractively(_ coordinator: RoomCoordinatorProtocol) {
        self.remove(childCoordinator: coordinator)
    }
        
    func roomCoordinatorDidLeaveRoom(_ coordinator: RoomCoordinatorProtocol) {
        // For the moment when a room is left, reset the split detail with placeholder
        self.resetSplitViewDetails()
    }
    
    func roomCoordinatorDidCancelRoomPreview(_ coordinator: RoomCoordinatorProtocol) {
        self.navigationRouter.popModule(animated: true)
    }
    
    func roomCoordinator(_ coordinator: RoomCoordinatorProtocol, didSelectRoomWithId roomId: String, eventId: String?) {
        self.showRoom(withId: roomId, eventId: eventId)
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
