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
import SafariServices
import SideMenu
import UIKit

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
    
    private lazy var sideMenuNavigationViewController: SideMenuNavigationController = self.createSideMenuNavigationController(with: self.sideMenuViewController)
    
    private let sideMenuViewController: SideMenuViewController
    
    let spaceMenuPresenter = SpaceMenuPresenter()
    let spaceDetailPresenter = SpaceDetailPresenter()
    
    private var exploreRoomCoordinator: ExploreRoomCoordinator?
    private var membersCoordinator: SpaceMembersCoordinator?
    private var createSpaceCoordinator: SpaceCreationCoordinator?
    private var createRoomCoordinator: CreateRoomCoordinator?
    private var spaceSettingsCoordinator: Coordinator?

    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: SideMenuCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(parameters: SideMenuCoordinatorParameters) {
        self.parameters = parameters
        
        let sideMenuViewModel = SideMenuViewModel(userSessionsService: self.parameters.userSessionsService, appInfo: parameters.appInfo)
        sideMenuViewController = SideMenuViewController.instantiate(with: sideMenuViewModel)
        self.sideMenuViewModel = sideMenuViewModel
    }
    
    // MARK: - Public methods
    
    func start() {
        sideMenuViewModel.coordinatorDelegate = self
        
        sideMenuNavigationViewController.sideMenuDelegate = self
        sideMenuNavigationViewController.dismissOnRotation = false
        
        // Set the sideMenuNavigationViewController as default left menu
        SideMenuManager.default.leftMenuNavigationController = sideMenuNavigationViewController
        
        addSpaceListIfNeeded()
        registerUserSessionsServiceNotifications()
    }
    
    func toPresentable() -> UIViewController {
        sideMenuNavigationViewController
    }
    
    @discardableResult func addScreenEdgePanGesturesToPresent(to view: UIView) -> UIScreenEdgePanGestureRecognizer {
        sideMenuNavigationViewController.sideMenuManager.addScreenEdgePanGesturesToPresent(toView: view, forMenu: .left)
    }
    
    @discardableResult func addPanGestureToPresent(to view: UIView) -> UIPanGestureRecognizer {
        sideMenuNavigationViewController.sideMenuManager.addPanGestureToPresent(toView: view)
    }
    
    func select(spaceWithId spaceId: String) {
        spaceListCoordinator?.select(spaceWithId: spaceId)
    }
    
    // MARK: - Private
    
    private func createSideMenuNavigationController(with rootViewController: UIViewController) -> SideMenuNavigationController {
        var sideMenuSettings = SideMenuSettings()
        sideMenuSettings.presentationStyle = .viewSlideOut
        sideMenuSettings.menuWidth = getMenuWidth()
        
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
        guard spaceListCoordinator == nil else {
            return
        }
        
        guard let mainMatrixSession = parameters.userSessionsService.mainUserSession?.matrixSession else {
            return
        }
        
        addSpaceList(with: mainMatrixSession)
    }

    private func addSpaceList(with matrixSession: MXSession) {
        let parameters = SpaceListCoordinatorParameters(userSessionsService: parameters.userSessionsService)
        
        let spaceListCoordinator = SpaceListCoordinator(parameters: parameters)
        spaceListCoordinator.delegate = self
        spaceListCoordinator.start()
        
        let spaceListPresentable = spaceListCoordinator.toPresentable()
            
        // sideMenuViewController.spaceListContainerView can be nil, load controller view to avoid this case
        sideMenuViewController.loadViewIfNeeded()
        
        sideMenuViewController.vc_addChildViewController(viewController: spaceListPresentable, onView: sideMenuViewController.spaceListContainerView)
        
        add(childCoordinator: spaceListCoordinator)
        
        self.spaceListCoordinator = spaceListCoordinator
    }
    
    private func createSettingsViewController() -> SettingsViewController {
        let viewController = SettingsViewController.instantiate()
        viewController.loadViewIfNeeded()
        return viewController
    }
    
    private func showSettings() {
        let viewController = createSettingsViewController()
        
        // Push view controller and dismiss side menu
        sideMenuNavigationViewController.pushViewController(viewController, animated: true)
    }
    
    private func showBugReport() {
        let bugReportViewController = BugReportViewController()
        
        // Show in fullscreen to animate presentation along side menu dismiss
        bugReportViewController.modalPresentationStyle = .fullScreen
        bugReportViewController.modalTransitionStyle = .crossDissolve
        
        sideMenuNavigationViewController.present(bugReportViewController, animated: true)
    }
    
    private func showHelp() {
        guard let helpURL = URL(string: BuildSettings.applicationHelpUrlString) else {
            return
        }
        
        let safariViewController = SFSafariViewController(url: helpURL)
        
        // Show in fullscreen to animate presentation along side menu dismiss
        safariViewController.modalPresentationStyle = .fullScreen
        sideMenuNavigationViewController.present(safariViewController, animated: true, completion: nil)
    }
    
    private func showExploreRooms(spaceId: String, session: MXSession) {
        let exploreRoomCoordinator = ExploreRoomCoordinator(session: session, spaceId: spaceId)
        exploreRoomCoordinator.delegate = self
        let presentable = exploreRoomCoordinator.toPresentable()
        presentable.presentationController?.delegate = self
        sideMenuViewController.present(presentable, animated: true, completion: nil)
        exploreRoomCoordinator.start()
        
        self.exploreRoomCoordinator = exploreRoomCoordinator
    }
    
    private func showMembers(spaceId: String, session: MXSession) {
        let parameters = SpaceMembersCoordinatorParameters(userSessionsService: parameters.userSessionsService, session: session, spaceId: spaceId)
        let spaceMembersCoordinator = SpaceMembersCoordinator(parameters: parameters)
        spaceMembersCoordinator.delegate = self
        let presentable = spaceMembersCoordinator.toPresentable()
        presentable.presentationController?.delegate = self
        sideMenuViewController.present(presentable, animated: true, completion: nil)
        spaceMembersCoordinator.start()
        
        membersCoordinator = spaceMembersCoordinator
    }

    private func showInviteFriends(from sourceView: UIView?) {
        let myUserId = parameters.userSessionsService.mainUserSession?.userId ?? ""
        
        let inviteFriendsPresenter = InviteFriendsPresenter()
        inviteFriendsPresenter.present(for: myUserId, from: sideMenuViewController, sourceView: sourceView, animated: true)
    }
    
    private func showMenu(forSpaceWithId spaceId: String, from sourceView: UIView?) {
        guard let session = parameters.userSessionsService.mainUserSession?.matrixSession else {
            return
        }
        spaceMenuPresenter.delegate = self
        spaceMenuPresenter.present(forSpaceWithId: spaceId, from: sideMenuViewController, sourceView: sourceView, session: session, animated: true)
    }
    
    private func showSpaceDetail(forSpaceWithId spaceId: String, from sourceView: UIView?) {
        guard let session = parameters.userSessionsService.mainUserSession?.matrixSession else {
            return
        }
        spaceDetailPresenter.delegate = self
        spaceDetailPresenter.present(forSpaceWithId: spaceId, from: sideMenuViewController, sourceView: sourceView, session: session, animated: true)
    }
    
    private func showCreateSpace() {
        guard let session = parameters.userSessionsService.mainUserSession?.matrixSession else {
            return
        }
        
        let coordinator = SpaceCreationCoordinator(parameters: SpaceCreationCoordinatorParameters(session: session, parentSpaceId: nil))
        let presentable = coordinator.toPresentable()
        presentable.presentationController?.delegate = self
        sideMenuViewController.present(presentable, animated: true, completion: nil)
        coordinator.callback = { [weak self] result in
            guard let self = self else {
                return
            }
            
            self.createSpaceCoordinator?.toPresentable().dismiss(animated: true) {
                self.createSpaceCoordinator = nil
                switch result {
                case .cancel:
                    break
                case .done(let spaceId):
                    self.select(spaceWithId: spaceId)
                }
            }
        }
        coordinator.start()
        
        createSpaceCoordinator = coordinator
    }
    
    private func showAddRoom(spaceId: String, session: MXSession) {
        let space = session.spaceService.getSpace(withId: spaceId)
        let createRoomCoordinator = CreateRoomCoordinator(parameters: CreateRoomCoordinatorParameter(session: session, parentSpace: space))
        createRoomCoordinator.delegate = self
        let presentable = createRoomCoordinator.toPresentable()
        presentable.presentationController?.delegate = self
        toPresentable().present(presentable, animated: true, completion: nil)
        createRoomCoordinator.start()
        self.createRoomCoordinator = createRoomCoordinator
    }
    
    private func showSpaceSettings(spaceId: String, session: MXSession) {
        let coordinator = SpaceSettingsModalCoordinator(parameters: SpaceSettingsModalCoordinatorParameters(session: session, spaceId: spaceId, parentSpaceId: nil))
        coordinator.callback = { [weak self] _ in
            guard let self = self else { return }
            
            coordinator.toPresentable().dismiss(animated: true) {
                self.spaceSettingsCoordinator = nil
                self.resetExploringSpaceIfNeeded()
            }
        }
        
        let presentable = coordinator.toPresentable()
        presentable.presentationController?.delegate = self
        toPresentable().present(presentable, animated: true, completion: nil)
        coordinator.start()
        spaceSettingsCoordinator = coordinator
    }
    
    func showSpaceInvite(spaceId: String, session: MXSession) {
        guard let space = session.spaceService.getSpace(withId: spaceId), let spaceRoom = space.room else {
            MXLog.error("[SideMenuCoordinator] showSpaceInvite: failed to find space", context: [
                "space_id": spaceId
            ])
            return
        }
        
        spaceRoom.state { [weak self] roomState in
            guard let self = self else { return }
            
            guard let powerLevels = roomState?.powerLevels, let userId = session.myUserId else {
                MXLog.error("[SpaceMembersCoordinator] spaceMemberListCoordinatorShowInvite: failed to find powerLevels for room")
                return
            }
            let userPowerLevel = powerLevels.powerLevelOfUser(withUserID: userId)
            
            guard userPowerLevel >= powerLevels.invite else {
                let alert = UIAlertController(title: VectorL10n.spacesInvitePeople, message: VectorL10n.spaceInviteNotEnoughPermission, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: VectorL10n.ok, style: .default, handler: nil))
                self.sideMenuViewController.present(alert, animated: true)
                return
            }
            
            let coordinator = ContactsPickerCoordinator(session: session, room: spaceRoom, initialSearchText: nil, actualParticipants: nil, invitedParticipants: nil, userParticipant: nil)
            coordinator.delegate = self
            coordinator.start()
            self.add(childCoordinator: coordinator)
            self.sideMenuViewController.present(coordinator.toPresentable(), animated: true)
        }
    }

    private func resetExploringSpaceIfNeeded() {
        if sideMenuNavigationViewController.presentedViewController == nil {
            Analytics.shared.exploringSpace = nil
        }
    }

    // MARK: UserSessions management
    
    private func registerUserSessionsServiceNotifications() {
        // Listen only notifications from the current UserSessionsService instance
        let userSessionService = parameters.userSessionsService
        
        NotificationCenter.default.addObserver(self, selector: #selector(userSessionsServiceDidAddUserSession(_:)), name: UserSessionsService.didAddUserSession, object: userSessionService)
    }
    
    @objc private func userSessionsServiceDidAddUserSession(_ notification: Notification) {
        addSpaceListIfNeeded()
    }
}

// MARK: - SideMenuViewModelCoordinatorDelegate

extension SideMenuCoordinator: SideMenuViewModelCoordinatorDelegate {
    func sideMenuViewModel(_ viewModel: SideMenuViewModelType, didTapMenuItem menuItem: SideMenuItem, fromSourceView sourceView: UIView) {
        switch menuItem {
        case .inviteFriends:
            showInviteFriends(from: sourceView)
        case .settings:
            showSettings()
        case .help:
            showHelp()
        case .feedback:
            showBugReport()
        }
        
        delegate?.sideMenuCoordinator(self, didTapMenuItem: menuItem, fromSourceView: sourceView)
    }
}

// MARK: - SideMenuNavigationControllerDelegate

extension SideMenuCoordinator: SideMenuNavigationControllerDelegate {
    func sideMenuWillAppear(menu: SideMenuNavigationController, animated: Bool) { }
    
    func sideMenuDidAppear(menu: SideMenuNavigationController, animated: Bool) { }
    
    func sideMenuWillDisappear(menu: SideMenuNavigationController, animated: Bool) { }
    
    func sideMenuDidDisappear(menu: SideMenuNavigationController, animated: Bool) { }
}

// MARK: - SideMenuNavigationControllerDelegate

extension SideMenuCoordinator: SpaceListCoordinatorDelegate {
    func spaceListCoordinatorDidSelectHomeSpace(_ coordinator: SpaceListCoordinatorType) {
        parameters.appNavigator.sideMenu.dismiss(animated: true) { }
        parameters.appNavigator.navigate(to: .homeSpace)
    }
    
    func spaceListCoordinator(_ coordinator: SpaceListCoordinatorType, didSelectSpaceWithId spaceId: String) {
        parameters.appNavigator.sideMenu.dismiss(animated: true) { }
        parameters.appNavigator.navigate(to: .space(spaceId))
    }
    
    func spaceListCoordinator(_ coordinator: SpaceListCoordinatorType, didSelectInviteWithId spaceId: String, from sourceView: UIView?) {
        showSpaceDetail(forSpaceWithId: spaceId, from: sourceView)
    }
    
    func spaceListCoordinator(_ coordinator: SpaceListCoordinatorType, didPressMoreForSpaceWithId spaceId: String, from sourceView: UIView) {
        showMenu(forSpaceWithId: spaceId, from: sourceView)
    }
    
    func spaceListCoordinatorDidSelectCreateSpace(_ coordinator: SpaceListCoordinatorType) {
        showCreateSpace()
    }
}

// MARK: - SpaceMenuPresenterDelegate

extension SideMenuCoordinator: SpaceMenuPresenterDelegate {
    func spaceMenuPresenter(_ presenter: SpaceMenuPresenter, didCompleteWith action: SpaceMenuPresenter.Actions, forSpaceWithId spaceId: String, with session: MXSession) {
        presenter.dismiss(animated: false) {
            switch action {
            case .exploreRooms:
                Analytics.shared.viewRoomTrigger = .spaceMenu
                self.showExploreRooms(spaceId: spaceId, session: session)
            case .exploreMembers:
                Analytics.shared.viewRoomTrigger = .spaceMenu
                self.showMembers(spaceId: spaceId, session: session)
            case .addRoom:
                session.spaceService.getSpace(withId: spaceId)?.canAddRoom { canAddRoom in
                    if canAddRoom {
                        self.showAddRoom(spaceId: spaceId, session: session)
                    } else {
                        let alert = UIAlertController(title: VectorL10n.spacesAddRoom, message: VectorL10n.spacesAddRoomMissingPermissionMessage, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: VectorL10n.ok, style: .default, handler: nil))
                        self.toPresentable().present(alert, animated: true, completion: nil)
                    }
                }
            case .addSpace:
                AppDelegate.theDelegate().showAlert(withTitle: VectorL10n.spacesAddSpace, message: VectorL10n.spacesFeatureNotAvailable(AppInfo.current.displayName))
            case .settings:
                self.showSpaceSettings(spaceId: spaceId, session: session)
            case .invite:
                self.showSpaceInvite(spaceId: spaceId, session: session)
            }
        }
    }
}

extension SideMenuCoordinator: SpaceDetailPresenterDelegate {
    func spaceDetailPresenter(_ presenter: SpaceDetailPresenter, didJoinSpaceWithId spaceId: String) {
        spaceListCoordinator?.select(spaceWithId: spaceId)
    }
    
    func spaceDetailPresenter(_ presenter: SpaceDetailPresenter, didOpenSpaceWithId spaceId: String) {
        // this use case cannot happen here as the space list open directly joined spaces on tap
        spaceListCoordinator?.revertItemSelection()
    }
    
    func spaceDetailPresenterDidComplete(_ presenter: SpaceDetailPresenter) {
        spaceListCoordinator?.revertItemSelection()
    }
}

// MARK: - ExploreRoomCoordinatorDelegate

extension SideMenuCoordinator: ExploreRoomCoordinatorDelegate {
    func exploreRoomCoordinatorDidComplete(_ coordinator: ExploreRoomCoordinatorType) {
        exploreRoomCoordinator?.toPresentable().dismiss(animated: true) {
            self.exploreRoomCoordinator = nil
            self.resetExploringSpaceIfNeeded()
        }
    }
}

// MARK: - SpaceMembersCoordinatorDelegate

extension SideMenuCoordinator: SpaceMembersCoordinatorDelegate {
    func spaceMembersCoordinatorDidCancel(_ coordinator: SpaceMembersCoordinatorType) {
        membersCoordinator?.toPresentable().dismiss(animated: true) {
            self.membersCoordinator = nil
            self.resetExploringSpaceIfNeeded()
        }
    }
}

// MARK: - CreateRoomCoordinatorDelegate

extension SideMenuCoordinator: CreateRoomCoordinatorDelegate {
    func createRoomCoordinator(_ coordinator: CreateRoomCoordinatorType, didCreateNewRoom room: MXRoom) {
        coordinator.toPresentable().dismiss(animated: true) {
            self.createRoomCoordinator = nil
            self.parameters.appNavigator.sideMenu.dismiss(animated: true) {
                self.resetExploringSpaceIfNeeded()
            }
            if let spaceId = coordinator.parentSpace?.spaceId {
                self.parameters.appNavigator.navigate(to: .space(spaceId))
            }
        }
    }
    
    func createRoomCoordinator(_ coordinator: CreateRoomCoordinatorType, didAddRoomsWithIds roomIds: [String]) {
        coordinator.toPresentable().dismiss(animated: true) {
            self.createRoomCoordinator = nil
            self.parameters.appNavigator.sideMenu.dismiss(animated: true) {
                self.resetExploringSpaceIfNeeded()
            }
            if let spaceId = coordinator.parentSpace?.spaceId {
                self.parameters.appNavigator.navigate(to: .space(spaceId))
            }
        }
    }

    func createRoomCoordinatorDidCancel(_ coordinator: CreateRoomCoordinatorType) {
        coordinator.toPresentable().dismiss(animated: true) {
            self.createRoomCoordinator = nil
            self.resetExploringSpaceIfNeeded()
        }
    }
}

// MARK: - ContactsPickerCoordinatorDelegate

extension SideMenuCoordinator: ContactsPickerCoordinatorDelegate {
    func contactsPickerCoordinatorDidStartLoading(_ coordinator: ContactsPickerCoordinatorProtocol) { }
    
    func contactsPickerCoordinatorDidEndLoading(_ coordinator: ContactsPickerCoordinatorProtocol) { }
    
    func contactsPickerCoordinatorDidClose(_ coordinator: ContactsPickerCoordinatorProtocol) {
        remove(childCoordinator: coordinator)
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension SideMenuCoordinator: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        exploreRoomCoordinator = nil
        membersCoordinator = nil
        createSpaceCoordinator = nil
        createRoomCoordinator = nil
        spaceSettingsCoordinator = nil
        resetExploringSpaceIfNeeded()
    }
}
