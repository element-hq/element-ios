// File created from FlowTemplate
// $ createRootCoordinator.sh Spaces/SpaceRoomList ExploreRoom ShowSpaceExploreRoom
/*
 Copyright 2021 New Vector Ltd
 
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
final class ExploreRoomCoordinator: NSObject, ExploreRoomCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let navigationRouter: NavigationRouterType
    private let session: MXSession
    private let spaceId: String
    // We need to stack the ID of visited space and subspaces so we know what is the current space ID when navigating to a room
    private var spaceIdStack: [String]
    private weak var roomDetailCoordinator: SpaceChildRoomDetailCoordinator?
    private weak var currentExploreRoomCoordinator: SpaceExploreRoomCoordinator?
    private var pollEditFormCoordinator: PollEditFormCoordinator?

    private lazy var slidingModalPresenter: SlidingModalPresenter = {
        return SlidingModalPresenter()
    }()

    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: ExploreRoomCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, spaceId: String,
         navigationRouter: NavigationRouterType = NavigationRouter(navigationController: RiotNavigationController())) {
        self.navigationRouter = navigationRouter
        self.session = session
        self.spaceId = spaceId
        self.spaceIdStack = [spaceId]
    }
    
    // MARK: - Public methods
    
    func start() {

        let rootCoordinator = self.createShowSpaceExploreRoomCoordinator(session: self.session, spaceId: self.spaceId, spaceName: self.session.spaceService.getSpace(withId: self.spaceId)?.summary?.displayname)

        rootCoordinator.start()

        self.add(childCoordinator: rootCoordinator)
        self.currentExploreRoomCoordinator = rootCoordinator

        if self.navigationRouter.modules.isEmpty {
            self.navigationRouter.setRootModule(rootCoordinator)
        } else {
            self.navigationRouter.push(rootCoordinator, animated: true) {
                self.remove(childCoordinator: rootCoordinator)
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        return self.navigationRouter.toPresentable()
    }
    
    // MARK: - Private methods
    
    private func pushSpace(with item: SpaceExploreRoomListItemViewData) {
        pushSpace(with: item.childInfo.childRoomId, name: item.childInfo.name)
    }
    
    private func pushSpace(with spaceId: String, name: String?) {
        let coordinator = self.createShowSpaceExploreRoomCoordinator(session: self.session, spaceId: spaceId, spaceName: name)
        coordinator.start()
        
        self.add(childCoordinator: coordinator)
        self.currentExploreRoomCoordinator = coordinator

        self.spaceIdStack.append(spaceId)
        
        self.navigationRouter.push(coordinator.toPresentable(), animated: true) {
            self.remove(childCoordinator: coordinator)
            self.spaceIdStack.removeLast()
        }
    }
    
    private func presentRoom(with item: SpaceExploreRoomListItemViewData, from sourceView: UIView?) {
        if let currentCoordinator = self.roomDetailCoordinator {
            self.remove(childCoordinator: currentCoordinator)
        }
        
        let summary = self.session.room(withRoomId: item.childInfo.childRoomId)?.summary
        let isJoined = summary?.isJoined ?? false

        if isJoined {
            self.navigateTo(roomWith: item.childInfo.childRoomId)
        } else {
            self.showRoomPreview(with: item, from: sourceView)
        }
    }

    private func showRoomPreview(with item: SpaceExploreRoomListItemViewData, from sourceView: UIView?) {
        Analytics.shared.joinedRoomTrigger = .spaceHierarchy
        let coordinator = self.createShowSpaceRoomDetailCoordinator(session: self.session, childInfo: item.childInfo)
        coordinator.start()
        self.add(childCoordinator: coordinator)
        self.roomDetailCoordinator = coordinator
        
        if UIDevice.current.isPhone {
            slidingModalPresenter.present(coordinator.toSlidingPresentable(), from: self.navigationRouter.toPresentable(), animated: true, completion: nil)
        } else {
            let viewController = coordinator.toPresentable()
            viewController.modalPresentationStyle = .popover
            if let sourceView = sourceView, let popoverPresentationController = viewController.popoverPresentationController {
                popoverPresentationController.sourceView = sourceView
                popoverPresentationController.sourceRect = sourceView.bounds
            }

            self.navigationRouter.present(viewController, animated: true)
        }
    }

    private func createShowSpaceExploreRoomCoordinator(session: MXSession, spaceId: String, spaceName: String?) -> SpaceExploreRoomCoordinator {
        let coordinator = SpaceExploreRoomCoordinator(parameters: SpaceExploreRoomCoordinatorParameters(session: session, spaceId: spaceId, spaceName: spaceName, showCancelMenuItem: self.navigationRouter.modules.isEmpty))
        coordinator.delegate = self
        return coordinator
    }
    
    private func createShowSpaceRoomDetailCoordinator(session: MXSession, childInfo: MXSpaceChildInfo) -> SpaceChildRoomDetailCoordinator {
        let coordinator = SpaceChildRoomDetailCoordinator(parameters: SpaceChildRoomDetailCoordinatorParameters(session: session, childInfo: childInfo))
        coordinator.delegate = self
        return coordinator
    }
    
    private func navigateTo(roomWith roomId: String, showSettingsInitially: Bool = false, animated: Bool = true) {
        let roomDataSourceManager = MXKRoomDataSourceManager.sharedManager(forMatrixSession: self.session)
        roomDataSourceManager?.roomDataSource(forRoom: roomId, create: true, onComplete: { [weak self] roomDataSource in
            
            if let room = self?.session.room(withRoomId: roomId) {
                Analytics.shared.viewRoomTrigger = .spaceHierarchy
                Analytics.shared.trackViewRoom(room)
            }

            let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            guard let roomViewController = storyboard.instantiateViewController(withIdentifier: "RoomViewControllerStoryboardId") as? RoomViewController else {
                return
            }
            
            self?.navigationRouter.push(roomViewController, animated: animated, popCompletion: nil)
            roomViewController.parentSpaceId = self?.spaceIdStack.last
            roomViewController.showSettingsInitially = showSettingsInitially
            roomViewController.displayRoom(roomDataSource)
            roomViewController.navigationItem.leftItemsSupplementBackButton = true
            roomViewController.showMissedDiscussionsBadge = false
            roomViewController.delegate = self
        })
    }
    
    private func presentRoomCreation() {
        let space = session.spaceService.getSpace(withId: spaceIdStack.last ?? "")
        let createRoomCoordinator = CreateRoomCoordinator(parameters: CreateRoomCoordinatorParameter(session: self.session, parentSpace: space))
        createRoomCoordinator.delegate = self
        let presentable = createRoomCoordinator.toPresentable()
        presentable.presentationController?.delegate = self
        toPresentable().present(presentable, animated: true, completion: nil)
        createRoomCoordinator.start()
        self.add(childCoordinator: createRoomCoordinator)
    }
    
    private func popToLastSpaceScreen(animated: Bool) {
        if let lastSpaceScreen = self.currentExploreRoomCoordinator?.toPresentable() {
            self.navigationRouter.popToModule(lastSpaceScreen, animated: animated)
        } else {
            self.navigationRouter.popToRootModule(animated: animated)
        }
    }
    
    private func presentInviteScreen(forRoomWithId roomId: String) {
        guard let room = session.room(withRoomId: roomId) else {
            MXLog.error("[ExploreRoomCoordinator] pushInviteScreen: room not found.")
            return
        }
        
        let coordinator = ContactsPickerCoordinator(session: session, room: room, initialSearchText: nil, actualParticipants: nil, invitedParticipants: nil, userParticipant: nil, navigationRouter: navigationRouter)
        coordinator.delegate = self
        coordinator.start()
        self.add(childCoordinator: coordinator)
        self.navigationRouter.present(coordinator, animated: true)
    }
    
    private func showSpaceSettings(of childInfo: MXSpaceChildInfo) {
        let coordinator = SpaceSettingsModalCoordinator(parameters: SpaceSettingsModalCoordinatorParameters(session: session, spaceId: childInfo.childRoomId, parentSpaceId: spaceIdStack.last))
        coordinator.callback = { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .cancel(let spaceId), .done(let spaceId):
                if spaceId != childInfo.childRoomId {
                    // the space has been upgraded. We need to refresh the rooms list
                    self.currentExploreRoomCoordinator?.reloadRooms()
                }
                
                self.navigationRouter.dismissModule(animated: true) {
                    self.remove(childCoordinator: coordinator)
                }
            }
        }
        coordinator.start()
        self.add(childCoordinator: coordinator)
        self.navigationRouter.present(coordinator.toPresentable(), animated: true)
    }
    
    private func presentSettings(ofRoomWithId roomId: String) -> Bool {
        guard let room = session.room(withRoomId: roomId) else {
            return false
        }
        
        let coordinator = RoomInfoCoordinator(parameters: RoomInfoCoordinatorParameters(session: session, room: room, parentSpaceId: self.spaceIdStack.last, initialSection: .settings, dismissOnCancel: true))
        coordinator.delegate = self
        add(childCoordinator: coordinator)
        coordinator.start()
        self.navigationRouter.present(coordinator.toPresentable(), animated: true)
        return true
    }

    private func startEditPollCoordinator(room: MXRoom, startEvent: MXEvent? = nil) {
        let parameters = PollEditFormCoordinatorParameters(room: room, pollStartEvent: startEvent)
        let coordinator = PollEditFormCoordinator(parameters: parameters)
        
        coordinator.completion = { [weak self, weak coordinator] in
            guard let self = self, let coordinator = coordinator else {
                return
            }
            
            self.navigationRouter.dismissModule(animated: true, completion: nil)
            self.remove(childCoordinator: coordinator)
        }
        
        add(childCoordinator: coordinator)
        
        navigationRouter.present(coordinator, animated: true)
        coordinator.start()
    }
}

// MARK: - ShowSpaceExploreRoomCoordinatorDelegate
extension ExploreRoomCoordinator: SpaceExploreRoomCoordinatorDelegate {
    func spaceExploreRoomCoordinator(_ coordinator: SpaceExploreRoomCoordinatorType, didSelect item: SpaceExploreRoomListItemViewData, from sourceView: UIView?) {
        if item.childInfo.roomType == .space {
            self.pushSpace(with: item)
        } else if item.childInfo.roomType == .room {
            self.presentRoom(with: item, from: sourceView)
        }
    }

    func spaceExploreRoomCoordinatorDidCancel(_ coordinator: SpaceExploreRoomCoordinatorType) {
        self.delegate?.exploreRoomCoordinatorDidComplete(self)
    }
    
    func spaceExploreRoomCoordinatorDidAddRoom(_ coordinator: SpaceExploreRoomCoordinatorType) {
        self.presentRoomCreation()
    }
    
    func spaceExploreRoomCoordinator(_ coordinator: SpaceExploreRoomCoordinatorType, openSettingsOf item: SpaceExploreRoomListItemViewData) {
        if item.childInfo.roomType == .space {
            self.showSpaceSettings(of: item.childInfo)
        } else {
            if !presentSettings(ofRoomWithId: item.childInfo.childRoomId) {
                self.navigateTo(roomWith: item.childInfo.childRoomId, showSettingsInitially: true, animated: true)
            }
        }
    }
    
    func spaceExploreRoomCoordinator(_ coordinator: SpaceExploreRoomCoordinatorType, inviteTo item: SpaceExploreRoomListItemViewData) {
        self.presentInviteScreen(forRoomWithId: item.childInfo.childRoomId)
    }
    
    func spaceExploreRoomCoordinator(_ coordinator: SpaceExploreRoomCoordinatorType, didJoin item: SpaceExploreRoomListItemViewData) {
        if item.childInfo.roomType == .space {
            self.pushSpace(with: item)
        } else {
            self.navigateTo(roomWith: item.childInfo.childRoomId)
        }
    }
}

// MARK: - ShowSpaceChildRoomDetailCoordinator
extension ExploreRoomCoordinator: SpaceChildRoomDetailCoordinatorDelegate {
    func spaceChildRoomDetailCoordinator(_ coordinator: SpaceChildRoomDetailCoordinatorType, didOpenRoomWith roomId: String) {
        self.navigationRouter.toPresentable().dismiss(animated: true) {
            if let lastCoordinator = self.roomDetailCoordinator {
                self.remove(childCoordinator: lastCoordinator)
            }
            self.navigateTo(roomWith: roomId)
        }
    }
    
    func spaceChildRoomDetailCoordinatorDidCancel(_ coordinator: SpaceChildRoomDetailCoordinatorType) {
        if UIDevice.current.isPhone {
            slidingModalPresenter.dismiss(animated: true) {
                if let roomDetailCoordinator = self.roomDetailCoordinator {
                    self.remove(childCoordinator: roomDetailCoordinator)
                }
            }
        } else {
            self.roomDetailCoordinator?.toPresentable().dismiss(animated: true, completion: {
                if let roomDetailCoordinator = self.roomDetailCoordinator {
                    self.remove(childCoordinator: roomDetailCoordinator)
                }
            })
        }
    }
}

// MARK: - CreateRoomCoordinatorDelegate
extension ExploreRoomCoordinator: CreateRoomCoordinatorDelegate {
    
    func createRoomCoordinator(_ coordinator: CreateRoomCoordinatorType, didCreateNewRoom room: MXRoom) {
        self.currentExploreRoomCoordinator?.reloadRooms()
        coordinator.toPresentable().dismiss(animated: true) {
            self.remove(childCoordinator: coordinator)
            self.navigateTo(roomWith: room.roomId)
        }
    }
    
    func createRoomCoordinator(_ coordinator: CreateRoomCoordinatorType, didAddRoomsWithIds roomIds: [String]) {
        self.currentExploreRoomCoordinator?.reloadRooms()
        coordinator.toPresentable().dismiss(animated: true) {
            self.remove(childCoordinator: coordinator)
        }
    }

    func createRoomCoordinatorDidCancel(_ coordinator: CreateRoomCoordinatorType) {
        coordinator.toPresentable().dismiss(animated: true) {
            self.remove(childCoordinator: coordinator)
        }
    }
    
}

// MARK: - UIAdaptivePresentationControllerDelegate
extension ExploreRoomCoordinator: UIAdaptivePresentationControllerDelegate {
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        guard let lastCoordinator = childCoordinators.last else {
            return
        }
        self.remove(childCoordinator: lastCoordinator)
    }
    
}

// MARK: - RoomViewControllerDelegate
extension ExploreRoomCoordinator: RoomViewControllerDelegate {
    func roomViewControllerShowRoomDetails(_ roomViewController: RoomViewController) {
        // TODO:
    }
    
    func roomViewController(_ roomViewController: RoomViewController, showMemberDetails roomMember: MXRoomMember) {
        // TODO:
    }
    
    func roomViewController(_ roomViewController: RoomViewController, showRoomWithId roomID: String, eventId eventID: String?) {
        self.navigateTo(roomWith: roomID)
    }
    
    func roomViewController(_ roomViewController: RoomViewController, didReplaceRoomWithReplacementId roomID: String) {
        self.currentExploreRoomCoordinator?.reloadRooms()
        self.popToLastSpaceScreen(animated: false)
        self.navigateTo(roomWith: roomID, showSettingsInitially: true, animated: false)
    }
    
    func roomViewController(_ roomViewController: RoomViewController, startChatWithUserId userId: String, completion: @escaping () -> Void) {
        // TODO:
    }
    
    func roomViewController(_ roomViewController: RoomViewController, showCompleteSecurityFor session: MXSession) {
        // TODO:
    }
    
    func roomViewControllerDidLeaveRoom(_ roomViewController: RoomViewController) {
        self.popToLastSpaceScreen(animated: true)
    }
    
    func roomViewControllerPreviewDidTapCancel(_ roomViewController: RoomViewController) {
        // TODO:
    }
    
    func roomViewController(_ roomViewController: RoomViewController, handleUniversalLinkWith parameters: UniversalLinkParameters) -> Bool {
        // TODO:
        return true
    }
    
    func roomViewController(_ roomViewController: RoomViewController, didRequestEditForPollWithStart startEvent: MXEvent) {
        startEditPollCoordinator(room: roomViewController.roomDataSource.room, startEvent: startEvent)
    }
    
    func roomViewControllerDidRequestLocationSharingFormPresentation(_ roomViewController: RoomViewController) {
        // TODO:
    }
    
    func roomViewController(_ roomViewController: RoomViewController, didRequestLiveLocationPresentationForBubbleData bubbleData: MXKRoomBubbleCellDataStoring) {
        // TODO:
    }
    
    func roomViewController(_ roomViewController: RoomViewController, didRequestLocationPresentationFor event: MXEvent, bubbleData: MXKRoomBubbleCellDataStoring) {
        // TODO:
    }

    func roomViewController(_ roomViewController: RoomViewController, locationShareActivityViewControllerFor event: MXEvent) -> UIActivityViewController? {
        guard let location = event.location else {
            return nil
        }
        
        return LocationSharingCoordinator.shareLocationActivityController(CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude))
    }

    func roomViewController(_ roomViewController: RoomViewController, canEditPollWithEventIdentifier eventIdentifier: String) -> Bool {
        return TimelinePollProvider.shared.timelinePollCoordinatorForEventIdentifier(eventIdentifier)?.canEditPoll() ?? false
    }

    func roomViewController(_ roomViewController: RoomViewController, endPollWithEventIdentifier eventIdentifier: String) {
        TimelinePollProvider.shared.timelinePollCoordinatorForEventIdentifier(eventIdentifier)?.endPoll()
    }
    
    func roomViewControllerDidRequestPollCreationFormPresentation(_ roomViewController: RoomViewController) {
        startEditPollCoordinator(room: roomViewController.roomDataSource.room)
    }
    
    func roomViewController(_ roomViewController: RoomViewController, canEndPollWithEventIdentifier eventIdentifier: String) -> Bool {
        return TimelinePollProvider.shared.timelinePollCoordinatorForEventIdentifier(eventIdentifier)?.canEndPoll() ?? false
    }
    
    func roomViewControllerDidStartLoading(_ roomViewController: RoomViewController) {
        
    }
    
    func roomViewControllerDidStopLoading(_ roomViewController: RoomViewController) {
        
    }
    
    func roomViewControllerDidTapLiveLocationSharingBanner(_ roomViewController: RoomViewController) {
        // TODO:
    }
    
    func roomViewControllerDidStopLiveLocationSharing(_ roomViewController: RoomViewController, beaconInfoEventId: String?) {
        // TODO:
    }
    
    func threadsCoordinator(for roomViewController: RoomViewController, threadId: String?) -> ThreadsCoordinatorBridgePresenter? {
        guard let roomId = roomViewController.roomPreviewData?.roomId else {
            MXLog.error("[ExploreRoomCoordinator] Cannot create threads coordinator for room")
            return nil
        }
        
        return ThreadsCoordinatorBridgePresenter(
            session: session,
            roomId: roomId,
            threadId: threadId,
            userIndicatorPresenter: UserIndicatorTypePresenter(presentingViewController: toPresentable())
        )
    }
}

// MARK: - ContactsPickerCoordinatorDelegate
extension ExploreRoomCoordinator: ContactsPickerCoordinatorDelegate {
    func contactsPickerCoordinatorDidStartLoading(_ coordinator: ContactsPickerCoordinatorProtocol) {
    }
    
    func contactsPickerCoordinatorDidEndLoading(_ coordinator: ContactsPickerCoordinatorProtocol) {
    }
    
    func contactsPickerCoordinatorDidClose(_ coordinator: ContactsPickerCoordinatorProtocol) {
        childCoordinators.removeLast()
    }
    
}

// MARK: - RoomInfoCoordinatorDelegate
extension ExploreRoomCoordinator: RoomInfoCoordinatorDelegate {
    func roomInfoCoordinatorDidComplete(_ coordinator: RoomInfoCoordinatorType) {
        self.navigationRouter.dismissModule(animated: true) {
            self.remove(childCoordinator: coordinator)
        }
    }
    
    func roomInfoCoordinator(_ coordinator: RoomInfoCoordinatorType, didRequestMentionForMember member: MXRoomMember) {
        // Do nothing in this case
    }
    
    func roomInfoCoordinatorDidLeaveRoom(_ coordinator: RoomInfoCoordinatorType) {
        self.currentExploreRoomCoordinator?.reloadRooms()
        
        self.navigationRouter.dismissModule(animated: true) {
            self.remove(childCoordinator: coordinator)
        }
    }
    
    func roomInfoCoordinator(_ coordinator: RoomInfoCoordinatorType, didReplaceRoomWithReplacementId roomId: String) {
        self.currentExploreRoomCoordinator?.reloadRooms()
        
        self.navigationRouter.dismissModule(animated: true) {
            self.remove(childCoordinator: coordinator)
        }
    }
    
}
