// File created from ScreenTemplate
// $ createScreen.sh SideMenu SideMenu
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
import UIKit
import SideMenu
import SafariServices

class SideMenuCoordinatorParameters {
    let appNavigator: AppNavigatorProtocol
    let userSessionsService: UserSessionsService
    let appInfo: AppInfo
    
    init(appNavigator: AppNavigatorProtocol,
         userSessionsService: UserSessionsService,
         appInfo: AppInfo) {
        self.appNavigator = appNavigator
        self.userSessionsService = userSessionsService
        self.appInfo = appInfo
    }
}

final class SideMenuCoordinator: NSObject, SideMenuCoordinatorType {
    
    // MARK: - Constants
    
    private enum SideMenu {
        static let widthRatio: CGFloat = 0.82
        static let maxWidthiPad: CGFloat = 320.0
    }
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: SideMenuCoordinatorParameters
    private var sideMenuViewModel: SideMenuViewModelType
    
    private weak var spaceListCoordinator: SpaceListCoordinatorType?
    
    private lazy var sideMenuNavigationViewController: SideMenuNavigationController = {
        return self.createSideMenuNavigationController(with: self.sideMenuViewController)
    }()
    
    private let sideMenuViewController: SideMenuViewController
    
    let spaceMenuPresenter = SpaceMenuPresenter()
    let spaceDetailPresenter = SpaceDetailPresenter()
    
    private var exploreRoomCoordinator: ExploreRoomCoordinator?
    private var membersCoordinator: SpaceMembersCoordinator?

    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: SideMenuCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(parameters: SideMenuCoordinatorParameters) {
        self.parameters = parameters
        
        let sideMenuViewModel = SideMenuViewModel(userSessionsService: self.parameters.userSessionsService, appInfo: parameters.appInfo)
        self.sideMenuViewController = SideMenuViewController.instantiate(with: sideMenuViewModel)
        self.sideMenuViewModel = sideMenuViewModel
    }
    
    // MARK: - Public methods
    
    func start() {            
        self.sideMenuViewModel.coordinatorDelegate = self
        
        self.sideMenuNavigationViewController.sideMenuDelegate = self
        self.sideMenuNavigationViewController.dismissOnRotation = false
        
        // Set the sideMenuNavigationViewController as default left menu
        SideMenuManager.default.leftMenuNavigationController = self.sideMenuNavigationViewController
        
        self.addSpaceListIfNeeded()
        self.registerUserSessionsServiceNotifications()
    }
    
    func toPresentable() -> UIViewController {
        return self.sideMenuNavigationViewController
    }
    
    @discardableResult func addScreenEdgePanGesturesToPresent(to view: UIView) -> UIScreenEdgePanGestureRecognizer {
        return self.sideMenuNavigationViewController.sideMenuManager.addScreenEdgePanGesturesToPresent(toView: view, forMenu: .left)
    }
    
    @discardableResult func addPanGestureToPresent(to view: UIView) -> UIPanGestureRecognizer {
        return self.sideMenuNavigationViewController.sideMenuManager.addPanGestureToPresent(toView: view)
    }
    
    func select(spaceWithId spaceId: String) {
        self.spaceListCoordinator?.select(spaceWithId: spaceId)
    }
    
    // MARK: - Private
    
    private func createSideMenuNavigationController(with rootViewController: UIViewController) -> SideMenuNavigationController {

        var sideMenuSettings = SideMenuSettings()
        sideMenuSettings.presentationStyle = .viewSlideOut
        sideMenuSettings.menuWidth = self.getMenuWidth()
        
        let navigationController = SideMenuNavigationController(rootViewController: rootViewController, settings: sideMenuSettings)
        
        // FIX: SideMenuSettings are not taken into account at init apply them again
        navigationController.settings = sideMenuSettings

        return navigationController
    }
    
    private func getMenuWidth() -> CGFloat {
        let appScreenRect = UIApplication.shared.keyWindow?.bounds ?? UIWindow().bounds
        let minimumSize = min(appScreenRect.width, appScreenRect.height)
        
        let menuWidth: CGFloat
        
        if UIDevice.current.isPhone {
            menuWidth = round(minimumSize * SideMenu.widthRatio)
        } else {
            // Set a max menu width on iPad
            menuWidth = min(round(minimumSize * SideMenu.widthRatio), SideMenu.maxWidthiPad * SideMenu.widthRatio)
        }
        
        return menuWidth
    }
    
    private func addSpaceListIfNeeded() {
        guard self.spaceListCoordinator == nil else {
            return
        }
        
        guard let mainMatrixSession = self.parameters.userSessionsService.mainUserSession?.matrixSession else {
            return
        }
        
        self.addSpaceList(with: mainMatrixSession)
    }

    private func addSpaceList(with matrixSession: MXSession) {
        let parameters = SpaceListCoordinatorParameters(userSessionsService: self.parameters.userSessionsService)
        
        let spaceListCoordinator = SpaceListCoordinator(parameters: parameters)
        spaceListCoordinator.delegate = self
        spaceListCoordinator.start()
        
        let spaceListPresentable = spaceListCoordinator.toPresentable()
            
        // sideMenuViewController.spaceListContainerView can be nil, load controller view to avoid this case
        self.sideMenuViewController.loadViewIfNeeded()
        
        self.sideMenuViewController.vc_addChildViewController(viewController: spaceListPresentable, onView: self.sideMenuViewController.spaceListContainerView)
        
        self.add(childCoordinator: spaceListCoordinator)
        
        self.spaceListCoordinator = spaceListCoordinator
    }
    
    private func createSettingsViewController() -> SettingsViewController {
        let viewController: SettingsViewController = SettingsViewController.instantiate()
        viewController.loadViewIfNeeded()
        return viewController
    }
    
    private func showSettings() {
        let viewController = self.createSettingsViewController()
        
        // Push view controller and dismiss side menu
        self.sideMenuNavigationViewController.pushViewController(viewController, animated: true)
    }
    
    private func showBugReport() {
        let bugReportViewController = BugReportViewController()
        
        // Show in fullscreen to animate presentation along side menu dismiss
        bugReportViewController.modalPresentationStyle = .fullScreen
        bugReportViewController.modalTransitionStyle = .crossDissolve
        
        self.sideMenuNavigationViewController.present(bugReportViewController, animated: true)
    }
    
    private func showHelp() {
        guard let helpURL = URL(string: BuildSettings.applicationHelpUrlString) else {
            return
        }
        
        let safariViewController = SFSafariViewController(url: helpURL)
        
        // Show in fullscreen to animate presentation along side menu dismiss
        safariViewController.modalPresentationStyle = .fullScreen
        self.sideMenuNavigationViewController.present(safariViewController, animated: true, completion: nil)
    }
    
    private func showExploreRooms(spaceId: String, session: MXSession) {
        let exploreRoomCoordinator = ExploreRoomCoordinator(session: session, spaceId: spaceId)
        exploreRoomCoordinator.delegate = self
        let presentable = exploreRoomCoordinator.toPresentable()
        presentable.presentationController?.delegate = self
        self.sideMenuViewController.present(presentable, animated: true, completion: nil)
        exploreRoomCoordinator.start()
        
        self.exploreRoomCoordinator = exploreRoomCoordinator
    }
    
    private func showMembers(spaceId: String, session: MXSession) {
        let parameters = SpaceMembersCoordinatorParameters(userSessionsService: self.parameters.userSessionsService, session: session, spaceId: spaceId)
        let spaceMembersCoordinator = SpaceMembersCoordinator(parameters: parameters)
        spaceMembersCoordinator.delegate = self
        let presentable = spaceMembersCoordinator.toPresentable()
        presentable.presentationController?.delegate = self
        self.sideMenuViewController.present(presentable, animated: true, completion: nil)
        spaceMembersCoordinator.start()
        
        self.membersCoordinator = spaceMembersCoordinator
    }

    private func showInviteFriends(from sourceView: UIView?) {
        let myUserId = self.parameters.userSessionsService.mainUserSession?.userId ?? ""
        
        let inviteFriendsPresenter = InviteFriendsPresenter()
        inviteFriendsPresenter.present(for: myUserId, from: self.sideMenuViewController, sourceView: sourceView, animated: true)
    }
    
    private func showMenu(forSpaceWithId spaceId: String, from sourceView: UIView?) {
        guard let session = self.parameters.userSessionsService.mainUserSession?.matrixSession else {
            return
        }
        self.spaceMenuPresenter.delegate = self
        self.spaceMenuPresenter.present(forSpaceWithId: spaceId, from: self.sideMenuViewController, sourceView: sourceView, session: session, animated: true)
    }
    
    private func showSpaceDetail(forSpaceWithId spaceId: String, from sourceView: UIView?) {
        guard let session = self.parameters.userSessionsService.mainUserSession?.matrixSession else {
            return
        }
        self.spaceDetailPresenter.delegate = self
        self.spaceDetailPresenter.present(forSpaceWithId: spaceId, from: self.sideMenuViewController, sourceView: sourceView, session: session, animated: true)
    }
    
    // MARK: UserSessions management
    
    private func registerUserSessionsServiceNotifications() {
        
        // Listen only notifications from the current UserSessionsService instance
        let userSessionService = self.parameters.userSessionsService
        
        NotificationCenter.default.addObserver(self, selector: #selector(userSessionsServiceDidAddUserSession(_:)), name: UserSessionsService.didAddUserSession, object: userSessionService)
    }
    
    @objc private func userSessionsServiceDidAddUserSession(_ notification: Notification) {
        self.addSpaceListIfNeeded()
    }
}

// MARK: - SideMenuViewModelCoordinatorDelegate
extension SideMenuCoordinator: SideMenuViewModelCoordinatorDelegate {
    
    func sideMenuViewModel(_ viewModel: SideMenuViewModelType, didTapMenuItem menuItem: SideMenuItem, fromSourceView sourceView: UIView) {
        
        switch menuItem {
        case .inviteFriends:
            self.showInviteFriends(from: sourceView)
        case .settings:
            self.showSettings()
        case .help:
            self.showHelp()
        case .feedback:
            self.showBugReport()
        }
        
        self.delegate?.sideMenuCoordinator(self, didTapMenuItem: menuItem, fromSourceView: sourceView)
    }
}

// MARK: - SideMenuNavigationControllerDelegate
extension SideMenuCoordinator: SideMenuNavigationControllerDelegate {
 
    func sideMenuWillAppear(menu: SideMenuNavigationController, animated: Bool) {
    }
    
    func sideMenuDidAppear(menu: SideMenuNavigationController, animated: Bool) {
    }
    
    func sideMenuWillDisappear(menu: SideMenuNavigationController, animated: Bool) {
    }
    
    func sideMenuDidDisappear(menu: SideMenuNavigationController, animated: Bool) {
    }
}

// MARK: - SideMenuNavigationControllerDelegate
extension SideMenuCoordinator: SpaceListCoordinatorDelegate {
    func spaceListCoordinatorDidSelectHomeSpace(_ coordinator: SpaceListCoordinatorType) {                
        self.parameters.appNavigator.sideMenu.dismiss(animated: true) {
            
        }
        self.parameters.appNavigator.navigate(to: .homeSpace)
    }
    
    func spaceListCoordinator(_ coordinator: SpaceListCoordinatorType, didSelectSpaceWithId spaceId: String) {
        self.parameters.appNavigator.sideMenu.dismiss(animated: true) {
            
        }
        self.parameters.appNavigator.navigate(to: .space(spaceId))
    }
    
    func spaceListCoordinator(_ coordinator: SpaceListCoordinatorType, didSelectInviteWithId spaceId: String, from sourceView: UIView?) {
        self.showSpaceDetail(forSpaceWithId: spaceId, from: sourceView)
    }
    
    func spaceListCoordinator(_ coordinator: SpaceListCoordinatorType, didPressMoreForSpaceWithId spaceId: String, from sourceView: UIView) {
        self.showMenu(forSpaceWithId: spaceId, from: sourceView)
    }
}

// MARK: - SpaceMenuPresenterDelegate
extension SideMenuCoordinator: SpaceMenuPresenterDelegate {
    func spaceMenuPresenter(_ presenter: SpaceMenuPresenter, didCompleteWith action: SpaceMenuPresenter.Actions, forSpaceWithId spaceId: String, with session: MXSession) {
        presenter.dismiss(animated: false) {
            switch action {
            case .exploreRooms:
                self.showExploreRooms(spaceId: spaceId, session: session)
            case .exploreMembers:
                self.showMembers(spaceId: spaceId, session: session)
            }
        }
    }
}

extension SideMenuCoordinator: SpaceDetailPresenterDelegate {
    func spaceDetailPresenter(_ presenter: SpaceDetailPresenter, didJoinSpaceWithId spaceId: String) {
        self.spaceListCoordinator?.select(spaceWithId: spaceId)
    }
    
    func spaceDetailPresenter(_ presenter: SpaceDetailPresenter, didOpenSpaceWithId spaceId: String) {
        // this use case cannot happen here as the space list open directly joined spaces on tap
        self.spaceListCoordinator?.revertItemSelection()
    }
    
    func spaceDetailPresenterDidComplete(_ presenter: SpaceDetailPresenter) {
        self.spaceListCoordinator?.revertItemSelection()
    }
}

// MARK: - ExploreRoomCoordinatorDelegate
extension SideMenuCoordinator: ExploreRoomCoordinatorDelegate {
    func exploreRoomCoordinatorDidComplete(_ coordinator: ExploreRoomCoordinatorType) {
        self.exploreRoomCoordinator?.toPresentable().dismiss(animated: true) {
            self.exploreRoomCoordinator = nil
        }
    }
}

// MARK: - SpaceMembersCoordinatorDelegate
extension SideMenuCoordinator: SpaceMembersCoordinatorDelegate {
    func spaceMembersCoordinatorDidCancel(_ coordinator: SpaceMembersCoordinatorType) {
        self.membersCoordinator?.toPresentable().dismiss(animated: true) {
            self.membersCoordinator = nil
        }
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate
extension SideMenuCoordinator: UIAdaptivePresentationControllerDelegate {
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        self.exploreRoomCoordinator = nil
        self.membersCoordinator = nil
    }
}
