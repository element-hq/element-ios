/*
Copyright 2020-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation
import MatrixSDK
import CommonKit

/// SplitViewCoordinatorParameters input parameters
class SplitViewCoordinatorParameters {
    
    let router: RootRouterType
    let userSessionsService: UserSessionsService
    let appNavigator: AppNavigatorProtocol
    
    init(router: RootRouterType, userSessionsService: UserSessionsService, appNavigator: AppNavigatorProtocol) {
        self.router = router
        self.userSessionsService = userSessionsService
        self.appNavigator = appNavigator
    }
}

final class SplitViewCoordinator: NSObject, SplitViewCoordinatorType {
    
    // MARK: - Constants
    
    private enum Constants {
        static let detailModulesCheckDelay: Double = 0.3
    }
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: SplitViewCoordinatorParameters
    
    private let splitViewController: UISplitViewController
    
    private weak var masterPresentable: SplitViewMasterPresentable?
    private var detailNavigationController: UINavigationController?
    private var detailNavigationRouter: NavigationRouterType?
    
    private var selectedNavigationRouter: NavigationRouterType? {
        return self.masterPresentable?.selectedNavigationRouter
    }
    
    private weak var masterCoordinator: SplitViewMasterCoordinatorProtocol?
    
    // Indicate if coordinator has been started once
    private var hasStartedOnce: Bool = false
    
    // MARK: Public
    
    private(set) var detailUserIndicatorPresenter: UserIndicatorTypePresenterProtocol?
    
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
        self.start(with: nil)
    }
    
    func start(with spaceId: String?) {
        
        if hasStartedOnce == false {
            self.hasStartedOnce = true
            
            self.splitViewController.delegate = self
            
            // Create primary controller
            let masterCoordinator: SplitViewMasterCoordinatorProtocol = BuildSettings.newAppLayoutEnabled ? self.createAllChatsCoordinator() : self.createTabBarCoordinator()
            masterCoordinator.splitViewMasterPresentableDelegate = self
            masterCoordinator.start(with: spaceId)
            
            // Create secondary controller
            let placeholderDetailViewController = self.createPlaceholderDetailsViewController()
            let detailNavigationController = RiotNavigationController(rootViewController: placeholderDetailViewController)
            
            // Setup split view controller
            self.splitViewController.viewControllers = [masterCoordinator.toPresentable(), detailNavigationController]
            
            // Setup detail user indicator presenter
            let context = SplitViewUserIndicatorPresentationContext(
                splitViewController: splitViewController,
                masterCoordinator: masterCoordinator,
                detailNavigationController: detailNavigationController
            )
            detailUserIndicatorPresenter = UserIndicatorTypePresenter(presentationContext: context)
                    
            self.add(childCoordinator: masterCoordinator)
            
            self.masterCoordinator = masterCoordinator
            self.masterPresentable = masterCoordinator
            self.detailNavigationController = detailNavigationController
            self.detailNavigationRouter = NavigationRouter(navigationController: detailNavigationController)
            
            self.parameters.router.setRootModule(self.splitViewController)
            
            self.registerNavigationRouterNotifications()
        } else {
            // Pop to home screen when selecting a new space
            self.popToHome(animated: true) {
                // Update tabBarCoordinator selected space
                self.masterCoordinator?.start(with: spaceId)
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        return self.splitViewController
    }
            
    // TODO: Do not expose publicly this method
    func resetDetails(animated: Bool) {
        // Be sure that the primary is then visible too.
        if splitViewController.displayMode == .primaryHidden {
            splitViewController.preferredDisplayMode = .allVisible
        }
        
        self.resetDetailNavigationController(animated: animated)

        // Release the current selected item (room/contact/group...).
        self.masterCoordinator?.releaseSelectedItems()
    }
    
    func popToHome(animated: Bool, completion: (() -> Void)?) {
        self.resetDetails(animated: animated)

        // Force back to the main screen if this is not the one that is displayed
        self.masterCoordinator?.popToHome(animated: animated, completion: completion)
    }
    
    func showErroIndicator(with error: Error) {
        masterCoordinator?.showErroIndicator(with: error)
    }
    
    func hideAppStateIndicator() {
        masterCoordinator?.hideAppStateIndicator()
    }
    
    func showAppStateIndicator(with text: String, icon: UIImage?) {
        masterCoordinator?.showAppStateIndicator(with: text, icon: icon)
    }

    // MARK: - Private methods
    
    private func createPlaceholderDetailsViewController() -> UIViewController {
        return PlaceholderDetailViewController.instantiate()
    }
    
    private func createAllChatsCoordinator() -> AllChatsCoordinator {
        let coordinatorParameters = AllChatsCoordinatorParameters(userSessionsService: self.parameters.userSessionsService, appNavigator: self.parameters.appNavigator)
        
        let coordinator = AllChatsCoordinator(parameters: coordinatorParameters)
        coordinator.delegate = self
        return coordinator
    }
    
    private func createTabBarCoordinator() -> TabBarCoordinator {
        
        let coordinatorParameters = TabBarCoordinatorParameters(userSessionsService: self.parameters.userSessionsService, appNavigator: self.parameters.appNavigator)
        
        let tabBarCoordinator = TabBarCoordinator(parameters: coordinatorParameters)
        tabBarCoordinator.delegate = self
        return tabBarCoordinator
    }
    
    private func resetDetailNavigationControllerWithPlaceholder(animated: Bool) {
        guard let detailNavigationRouter = self.detailNavigationRouter else {
            return
        }
        
        // Check if placeholder is already shown
        if detailNavigationRouter.modules.count == 1 && detailNavigationRouter.modules.last is PlaceholderDetailViewController {
            return
        }
        
        // Set placeholder screen as root controller of detail navigation controller
        let placeholderDetailsVC = self.createPlaceholderDetailsViewController()
        detailNavigationRouter.setRootModule(placeholderDetailsVC, hideNavigationBar: false, animated: animated, popCompletion: nil)
    }
    
    private func resetDetailNavigationController(animated: Bool) {
        
        if self.splitViewController.isCollapsed {
            if let topMostNavigationController = self.selectedNavigationRouter?.modules.last as? UINavigationController, topMostNavigationController == self.detailNavigationController {
                self.selectedNavigationRouter?.popModule(animated: animated)
            }
        } else {
            self.resetDetailNavigationControllerWithPlaceholder(animated: animated)
        }
    }
    
    private func isPlaceholderShown(from secondaryViewController: UIViewController) -> Bool {
        
        if let detailNavigationController = secondaryViewController as? UINavigationController, let topViewController = detailNavigationController.viewControllers.last {
            return topViewController is PlaceholderDetailViewController
        } else {
            return secondaryViewController is PlaceholderDetailViewController
        }
    }
    
    private func releaseRoomDataSourceIfNeeded(for roomCoordinator: RoomCoordinatorProtocol) {

        guard roomCoordinator.canReleaseRoomDataSource,
              let session = roomCoordinator.mxSession,
              let roomId = roomCoordinator.roomId else {
            return
        }

        let existingRoomCoordinatorWithSameRoomId = self.detailModules.first { presentable -> Bool in
            if let currentRoomCoordinator = presentable as? RoomCoordinatorProtocol, currentRoomCoordinator.threadId == nil {
                return currentRoomCoordinator.roomId == roomCoordinator.roomId
            }
            return false
        }

        guard existingRoomCoordinatorWithSameRoomId == nil else {
            MXLog.debug("[SplitViewCoordinator] Do not release RoomDataSource for room id \(roomId), another RoomCoordinator with same room id using it")
            return
        }

        let dataSourceManager = MXKRoomDataSourceManager.sharedManager(forMatrixSession: session)
        dataSourceManager?.closeRoomDataSource(withRoomId: roomId, forceClose: false)
    }
    
    private func registerNavigationRouterNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(navigationRouterDidPopViewController(_:)), name: NavigationRouter.didPopModule, object: nil)
    }
    
    @objc private func navigationRouterDidPopViewController(_ notification: Notification) {
        
        guard let userInfo = notification.userInfo,
              let navigationRouter = userInfo[NavigationRouter.NotificationUserInfoKey.navigationRouter] as? NavigationRouterType,
              let poppedController = userInfo[NavigationRouter.NotificationUserInfoKey.viewController] as? UIViewController else {
            return
        }
        
        // In our split view configuration is possible to have nested navigation controller (see https://blog.malcolmhall.com/2017/01/27/default-behaviour-of-uisplitviewcontroller-collapsesecondaryviewcontroller/)).
        // When the split view controller has one column visible with the detail navigation controller nested inside the primary,
        // check to see whether the primary navigation controller is popping the detail navigation controller.
        // In this case the detail navigation controller will be popped but not its content. It means completions will not be called.
        if navigationRouter === self.selectedNavigationRouter,
           let poppedNavigationController = poppedController as? UINavigationController,
           poppedNavigationController == self.detailNavigationController {
            
            // Clear the detailNavigationRouter to trigger completions associated to each controllers
            self.detailNavigationRouter?.popAllModules(animated: false)
        }
        
        if let poppedModule = userInfo[NavigationRouter.NotificationUserInfoKey.module] as? Presentable {
            
            if let roomCoordinator = poppedModule as? RoomCoordinatorProtocol {
                
                // If the RoomCoordinator view controller is popped from the detail navigation controller, check if the associated room data source should be released.
                // If there is no other RoomCoordinator using the same data source, release it.
                // A small delay is set to be sure navigation stack manipulation ended before checking the whole stack.
                DispatchQueue.main.asyncAfter(deadline: .now() + Constants.detailModulesCheckDelay) {
                    self.releaseRoomDataSourceIfNeeded(for: roomCoordinator)
                }
            }
        }
    }
}

// MARK: - UISplitViewControllerDelegate
extension SplitViewCoordinator: UISplitViewControllerDelegate {
    
    /// Provide the new secondary view controller for the split view interface.
    /// This method returns the view controller to use as the secondary view controller in the expanded split view interface (when 2 column are visible).
    /// Sample case: large iPhone goes from portrait to landsacpe.
    func splitViewController(_ splitViewController: UISplitViewController, separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
        
        // If the primary root controller of the UISplitViewController is a UINavigationController,
        // it's possible to have nested navigation controllers due to private property `_allowNestedNavigationControllers` set to true
        // (https://blog.malcolmhall.com/2017/01/27/default-behaviour-of-uisplitviewcontroller-collapsesecondaryviewcontroller/).
        // So if the top view controller of the primary navigation controller is a navigation controller and it corresponds to the existing `detailNavigationController` instance.
        // Return `detailNavigationController` as is, it will be used as the secondary view of the split view controller.
        if let topMostNavigationController = self.selectedNavigationRouter?.modules.last as? UINavigationController, topMostNavigationController == self.detailNavigationController {
            
            return self.detailNavigationController
        }

        // Else return the default empty details view controller.
        // Be sure that the primary is then visible too.
        if splitViewController.displayMode == .primaryHidden {
            splitViewController.preferredDisplayMode = .allVisible
        }
        
        // Restore detail navigation controller with placeholder as root
        self.resetDetailNavigationController(animated: false)
        
        // Return up to date detail navigation controller
        // In any cases `detailNavigationController` will be used as secondary view of the split view controller.
        return self.detailNavigationController
    }
    
    /// Adjust the primary view controller and incorporate the secondary view controller into the collapsed interface if needed.
    /// Return false to let the split view controller try to incorporate the secondary view controller's content into the collapsed interface,
    /// or true to indicate that you do not want the split view controller to do anything with the secondary view controller.
    /// Sample case: large iPhone goes from landscape to portrait.
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        
        // If the secondary view is the placeholder screen do not merge the secondary into the primary.
        // Note: In this case, the secondaryViewController will be automatically discarded.
        if self.isPlaceholderShown(from: secondaryViewController) {
            return true
        }
        
        // Return false to let the split view controller try to incorporate the secondary view controller's content into the collapsed interface.
        // If the primary root controller of a UISplitViewController is a UINavigationController,
        // it's possible to have nested navigation controllers due to private property `_allowNestedNavigationControllers` set to true
        // (https://blog.malcolmhall.com/2017/01/27/default-behaviour-of-uisplitviewcontroller-collapsesecondaryviewcontroller/).
        // So in this case returning false here will push the `detailNavigationController` on top of the `primaryNavigationController`.
        // Sample primary view stack:
        // primaryNavigationController[
        //   MasterTabBarController,
        //   detailNavigationController[RoomViewController, RoomInfoListViewController]]
        // Note that normally pushing a navigation controller on top of a navigation controller don't work.
        return false
    }
}

// MARK: - TabBarCoordinatorDelegate
extension SplitViewCoordinator: SplitViewMasterCoordinatorDelegate {
    func splitViewMasterCoordinatorDidCompleteAuthentication(_ coordinator: SplitViewMasterCoordinatorProtocol) {
        self.delegate?.splitViewCoordinatorDidCompleteAuthentication(self)
    }
}

// MARK: - SplitViewMasterPresentableDelegate
extension SplitViewCoordinator: SplitViewMasterPresentableDelegate {
    var detailModules: [Presentable] {
        return self.detailNavigationRouter?.modules ?? []
    }
    
    func splitViewMasterPresentable(_ presentable: Presentable, wantsToReplaceDetailWith detailPresentable: Presentable, popCompletion: (() -> Void)?) {
        MXLog.debug("[SplitViewCoordinator] splitViewMasterPresentable: \(presentable) wantsToReplaceDetailWith detailPresentable: \(detailPresentable)")
        
        guard let detailNavigationController = self.detailNavigationController else {
            MXLog.debug("[SplitViewCoordinator] splitViewMasterPresentable: Failed to display because detailNavigationController is nil")
            return
        }
        
        let detailController = detailPresentable.toPresentable()
        
        // Reset the detail navigation controller with the given detail controller
        self.detailNavigationRouter?.setRootModule(detailPresentable, popCompletion: popCompletion)
        
        // This will call first UISplitViewControllerDelegate method:  `splitViewController(_:showDetail:sender:)`, if implemented, to give the opportunity to customise `UISplitViewController.showDetailViewController(:sender:)` behavior.
        // - If the split view controller is collpased (one column visible):
        // The `detailNavigationController` will be pushed on top of the primary navigation controller.
        // In fact if the primary root controller of a UISplitViewController is a UINavigationController,
        // it's possible to have nested navigation controllers due to private property `_allowNestedNavigationControllers` set to true
        // (https://blog.malcolmhall.com/2017/01/27/default-behaviour-of-uisplitviewcontroller-collapsesecondaryviewcontroller/).
        // - Else if the split view controller is not collpased (two column visible)
        // It will set the `detailNavigationController` as the secondary view of the split view controller
        self.splitViewController.showDetailViewController(detailNavigationController, sender: nil)
        
        // Set leftBarButtonItem with split view display mode button if there is no leftBarButtonItem defined
        detailController.vc_setupDisplayModeLeftBarButtonItemIfNeeded()
    }
    
    func splitViewMasterPresentable(_ presentable: Presentable, wantsToStack detailPresentable: Presentable, popCompletion: (() -> Void)?) {
        
        guard let detailNavigationRouter = self.detailNavigationRouter else {
            MXLog.debug("[SplitViewCoordinator] Failed to stack \(detailPresentable) because detailNavigationRouter is nil")
            return
        }
        
        detailNavigationRouter.push(detailPresentable, animated: true, popCompletion: popCompletion)
    }
    
    func splitViewMasterPresentable(_ presentable: Presentable, wantsToReplaceDetailsWith modules: [NavigationModule]) {
        MXLog.debug("[SplitViewCoordinator] splitViewMasterPresentable: \(presentable) wantsToReplaceDetailsWith modules: \(modules)")
        
        self.detailNavigationRouter?.setModules(modules, animated: true)
    }
    
    func splitViewMasterPresentable(_ presentable: Presentable, wantsToStack modules: [NavigationModule]) {
        guard let detailNavigationRouter = self.detailNavigationRouter else {
            MXLog.warning("[SplitViewCoordinator] Failed to stack \(modules) because detailNavigationRouter is nil")
            return
        }
        
        detailNavigationRouter.push(modules, animated: true)
    }
    
    func splitViewMasterPresentable(_ presentable: Presentable, wantsToPopTo module: Presentable) {
        guard let detailNavigationRouter = self.detailNavigationRouter else {
            MXLog.warning("[SplitViewCoordinator] Failed to pop to \(module) because detailNavigationRouter is nil")
            return
        }
        
        detailNavigationRouter.popToModule(module, animated: true)
    }
    
    func splitViewMasterPresentableWantsToResetDetail(_ presentable: Presentable) {
        self.resetDetails(animated: false)
    }
}
