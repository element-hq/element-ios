// File created from FlowTemplate
// $ createRootCoordinator.sh Room2 RoomInfo RoomInfoList
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
final class RoomInfoCoordinator: NSObject, RoomInfoCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let navigationRouter: NavigationRouterType
    private let session: MXSession
    private let room: MXRoom
    private let parentSpaceId: String?
    private let initialSection: RoomInfoSection
    private let dismissOnCancel: Bool
    private let canAddParticipants: Bool
    private weak var roomSettingsViewController: RoomSettingsViewController?
    
    private lazy var segmentedViewController: SegmentedViewController = {
        let controller = SegmentedViewController()
        
        let participants = RoomParticipantsViewController()
        participants.finalizeInit()
        participants.enableMention = true
        participants.mxRoom = self.room
        participants.parentSpaceId = self.parentSpaceId
        participants.delegate = self
        participants.screenTracker = AnalyticsScreenTracker(screen: .roomMembers)
        participants.showInviteUserFab = self.canAddParticipants
        
        
        let files = RoomFilesViewController()
        files.finalizeInit()
        files.screenTracker = AnalyticsScreenTracker(screen: .roomUploads)
        MXKRoomDataSource.load(withRoomId: self.room.roomId, threadId: nil, andMatrixSession: self.session) { (dataSource) in
            guard let dataSource = dataSource as? MXKRoomDataSource else { return }
            dataSource.filterMessagesWithURL = true
            dataSource.finalizeInitialization()
            files.hasRoomDataSourceOwnership = true
            files.displayRoom(dataSource)
        }
        
        let settings = RoomSettingsViewController()
        settings.parentSpaceId = parentSpaceId
        settings.delegate = self
        settings.finalizeInit()
        settings.screenTracker = AnalyticsScreenTracker(screen: .roomSettings)
        settings.initWith(self.session, andRoomId: self.room.roomId)
        
        if self.room.isDirect {
            controller.title = VectorL10n.roomDetailsTitleForDm
        } else {
            controller.title = VectorL10n.roomDetailsTitle
        }
        controller.initWithTitles([
            VectorL10n.roomDetailsPeople,
            VectorL10n.roomDetailsFiles,
            VectorL10n.roomDetailsSettings
        ], viewControllers: [
            participants,
            files,
            settings
        ], defaultSelected: 0)
        controller.addMatrixSession(self.session)
        
        self.roomSettingsViewController = settings
        
        _ = controller.view
        
        return controller
    }()
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: RoomInfoCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(parameters: RoomInfoCoordinatorParameters, navigationRouter: NavigationRouterType? = nil) {
        if let navigationRouter = navigationRouter {
            self.navigationRouter = navigationRouter
        } else {
            self.navigationRouter = NavigationRouter(navigationController: RiotNavigationController())
        }

        self.session = parameters.session
        self.room = parameters.room
        self.parentSpaceId = parameters.parentSpaceId
        self.initialSection = parameters.initialSection
        self.canAddParticipants = parameters.canAddParticipants
        self.dismissOnCancel = parameters.dismissOnCancel
    }    
    
    // MARK: - Public methods
    
    func start() {
        let rootCoordinator = self.createRoomInfoListCoordinator()

        rootCoordinator.start()

        self.add(childCoordinator: rootCoordinator)
        
        if self.navigationRouter.modules.isEmpty == false {
            // push room info screen non animated if another screen needs to be pushed just after
            let animated = initialSection == .none
            self.navigationRouter.push(rootCoordinator.toPresentable(), animated: animated, popCompletion: nil)
        } else {
            self.navigationRouter.setRootModule(rootCoordinator)
        }

        switch initialSection {
        case .addParticipants:
            self.showRoomDetails(with: .members, animated: false)
        case .changeAvatar:
            self.showRoomDetails(with: .settings(RoomSettingsViewControllerFieldAvatar), animated: false)
        case .changeTopic:
            self.showRoomDetails(with: .settings(RoomSettingsViewControllerFieldTopic), animated: false)
        case .settings:
            self.showRoomDetails(with: .settings(RoomSettingsViewControllerFieldNone), animated: false)
        case .none:
            break
        }
    }
    
    func toPresentable() -> UIViewController {
        return self.navigationRouter.toPresentable()
    }
    
    // MARK: - Private methods

    private func createRoomInfoListCoordinator() -> RoomInfoListCoordinator {
        let coordinator = RoomInfoListCoordinator(session: self.session, room: room)
        coordinator.delegate = self
        return coordinator
    }
    
    private func createRoomNotificationSettingsCoordinator() -> RoomNotificationSettingsCoordinator {
        let coordinator = RoomNotificationSettingsCoordinator(room: room, presentedModally: false)
        coordinator.delegate = self
        return coordinator
    }
    
    private func showRoomDetails(with target: RoomInfoListTarget, animated: Bool) {
        switch target {
        case .integrations:
            if let modularVC = IntegrationManagerViewController(for: session, inRoom: room.roomId, screen: kIntegrationManagerMainScreen, widgetId: nil) {
                navigationRouter.present(modularVC, animated: true)
            }
        case .search:
            MXKRoomDataSourceManager.sharedManager(forMatrixSession: session)?.roomDataSource(forRoom: self.room.roomId, create: false, onComplete: { (roomDataSource) in
                guard let dataSource = roomDataSource else { return }
                let roomSearchViewController: RoomSearchViewController = RoomSearchViewController.instantiate()
                roomSearchViewController.loadViewIfNeeded()
                roomSearchViewController.roomDataSource = dataSource
                self.navigationRouter.push(roomSearchViewController, animated: animated, popCompletion: nil)
            })
        case .notifications:
            let coordinator = createRoomNotificationSettingsCoordinator()
            coordinator.start()
            push(coordinator: coordinator)
        case .pollHistory:
            let coordinator: PollHistoryCoordinator = .init(parameters: .init(mode: .active, room: room, navigationRouter: navigationRouter))
            coordinator.start()
            coordinator.completion = { [weak self] event in
                guard let self else { return }
                self.delegate?.roomInfoCoordinator(self, viewEventInTimeline: event)
            }
            push(coordinator: coordinator)
        default:
            guard let tabIndex = target.tabIndex else {
                fatalError("No settings tab index for this target.")
            }
            segmentedViewController.selectedIndex = tabIndex
            
            if case .settings(let roomSettingsField) = target {
                roomSettingsViewController?.selectedRoomSettingsField = roomSettingsField
            }
            
            navigationRouter.push(segmentedViewController, animated: animated, popCompletion: nil)
        }
    }
    
    private func push(coordinator: Coordinator & Presentable, animated: Bool = true) {
        self.add(childCoordinator: coordinator)
        navigationRouter.push(coordinator, animated: animated) {
            self.remove(childCoordinator: coordinator)
        }
    }
}

// MARK: - RoomInfoListCoordinatorDelegate
extension RoomInfoCoordinator: RoomInfoListCoordinatorDelegate {
    
    func roomInfoListCoordinator(_ coordinator: RoomInfoListCoordinatorType, wantsToNavigateTo target: RoomInfoListTarget) {
        self.showRoomDetails(with: target, animated: true)
    }
    
    func roomInfoListCoordinatorDidCancel(_ coordinator: RoomInfoListCoordinatorType) {
        self.delegate?.roomInfoCoordinatorDidComplete(self)
    }
    
    func roomInfoListCoordinatorDidLeaveRoom(_ coordinator: RoomInfoListCoordinatorType) {
        self.delegate?.roomInfoCoordinatorDidLeaveRoom(self)
    }

    func roomInfoListCoordinatorDidRequestReportRoom(_ coordinator: RoomInfoListCoordinatorType) {
        self.delegate?.roomInfoCoordinatorDidRequestReportRoom(self)
    }
}

extension RoomInfoCoordinator: RoomParticipantsViewControllerDelegate {
    
    func roomParticipantsViewController(_ roomParticipantsViewController: RoomParticipantsViewController!, mention member: MXRoomMember!) {
        self.navigationRouter.popToRootModule(animated: true)
        self.delegate?.roomInfoCoordinator(self, didRequestMentionForMember: member)
    }
    
}

extension RoomInfoCoordinator: RoomNotificationSettingsCoordinatorDelegate {
    func roomNotificationSettingsCoordinatorDidComplete(_ coordinator: RoomNotificationSettingsCoordinatorType) {
        self.navigationRouter.popModule(animated: true)
    }
    
    func roomNotificationSettingsCoordinatorDidCancel(_ coordinator: RoomNotificationSettingsCoordinatorType) {
        
    }
    
}

extension RoomInfoCoordinator: RoomSettingsViewControllerDelegate {
    func roomSettingsViewControllerDidCancel(_ controller: RoomSettingsViewController!) {
        if self.dismissOnCancel {
            self.navigationRouter.dismissModule(animated: true, completion: nil)
        } else {
            controller.withdrawViewController(animated: true) {}
        }
    }
    
    func roomSettingsViewControllerDidComplete(_ controller: RoomSettingsViewController!) {
        if self.dismissOnCancel {
            self.navigationRouter.dismissModule(animated: true, completion: nil)
        } else {
            controller.withdrawViewController(animated: true) {}
        }
    }
    
    func roomSettingsViewController(_ controller: RoomSettingsViewController!, didReplaceRoomWithReplacementId newRoomId: String!) {
        self.delegate?.roomInfoCoordinator(self, didReplaceRoomWithReplacementId: newRoomId)
    }
    
    func roomSettingsViewControllerDidLeaveRoom(_ controller: RoomSettingsViewController!) {
        self.delegate?.roomInfoCoordinatorDidLeaveRoom(self)
    }
}
