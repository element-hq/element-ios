// File created from ScreenTemplate
// $ createScreen.sh Room Room
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

import Foundation
import UIKit
import CommonKit
import MatrixSDK

final class RoomCoordinator: NSObject, RoomCoordinatorProtocol {

    // MARK: - Properties

    // MARK: Private

    private let parameters: RoomCoordinatorParameters
    private let roomViewController: RoomViewController
    private let userIndicatorStore: UserIndicatorStore
    private var selectedEventId: String?
    private var loadingCancel: UserIndicatorCancel?
    private var locationSharingIndicatorCancel: UserIndicatorCancel? // Used for location sharing advertizements
    
    private var roomDataSourceManager: MXKRoomDataSourceManager {
        return MXKRoomDataSourceManager.sharedManager(forMatrixSession: self.parameters.session)
    }
    
    /// Indicate true if the Coordinator has started once
    private var hasStartedOnce: Bool {
        return self.roomViewController.delegate != nil
    }
    
    private var navigationRouter: NavigationRouterType? {
        
        var finalNavigationRouter: NavigationRouterType?
        
        if let navigationRouter = self.parameters.navigationRouter {
            finalNavigationRouter = navigationRouter
        } else if let navigationRouterStore = self.parameters.navigationRouterStore, let currentNavigationController = self.roomViewController.navigationController {
            // If no navigationRouter has been provided, try to get the navigation router from the current RoomViewController navigation controller if exists
            finalNavigationRouter = navigationRouterStore.navigationRouter(for: currentNavigationController)
        }
        
        return finalNavigationRouter
    }

    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []

    weak var delegate: RoomCoordinatorDelegate?
    
    var canReleaseRoomDataSource: Bool {
        // If the displayed data is not a preview, let the manager release the room data source
        // (except if the view controller has the room data source ownership).
        return self.parameters.previewData == nil
            && self.roomViewController.roomDataSource != nil
            && self.roomViewController.roomDataSource.threadId == nil
            && self.roomViewController.hasRoomDataSourceOwnership == false
    }
    
    // MARK: - Setup

    init(parameters: RoomCoordinatorParameters) {
        self.parameters = parameters
        self.selectedEventId = parameters.eventId
        self.userIndicatorStore = UserIndicatorStore(presenter: parameters.userIndicatorPresenter)
        
        if let threadId = parameters.threadId {
            self.roomViewController = ThreadViewController.instantiate(withThreadId: threadId,
                                                                       configuration: parameters.displayConfiguration)
        } else {
            self.roomViewController = RoomViewController.instantiate(with: parameters.displayConfiguration)
        }
        self.roomViewController.userIndicatorStore = userIndicatorStore
        self.roomViewController.showSettingsInitially = parameters.showSettingsInitially
        
        self.roomViewController.parentSpaceId = parameters.parentSpaceId

        TimelinePollProvider.shared.session = parameters.session
        
        super.init()
    }
    
    deinit {
        roomViewController.destroy()
    }

    // MARK: - Public
    
    func start() {
        self.start(withCompletion: nil)
    }
    
    // NOTE: Completion closure has been added for legacy architecture purpose.
    // Remove this completion after LegacyAppDelegate refactor.
    func start(withCompletion completion: (() -> Void)?) {
        self.roomViewController.delegate = self
        
        // Detect when view controller has been dismissed by gesture when presented modally (not in full screen).
        // FIXME: Find a better way to manage modal dismiss. This makes the `roomViewController` to never be released
        // self.roomViewController.presentationController?.delegate = self
        
        if let previewData = self.parameters.previewData {
            self.loadRoomPreview(withData: previewData, completion: completion)
        } else if let roomId = self.parameters.roomId {
            if let threadId = self.parameters.threadId {
                self.loadRoom(withId: roomId,
                              andThreadId: threadId,
                              eventId: self.parameters.eventId,
                              completion: completion)
            } else if let eventId = self.selectedEventId {
                self.loadRoom(withId: roomId, andEventId: eventId, completion: completion)
            } else {
                self.loadRoom(withId: roomId, completion: completion)
            }
        } else if let userId = self.parameters.userId {
            // Start flow for a direct chat, try to find an existing room with target user
            self.loadRoom(withUserId: userId)
        }

        // Add `roomViewController` to the NavigationRouter, only if it has been explicitly set as parameter
        if let navigationRouter = self.parameters.navigationRouter {
            if navigationRouter.modules.isEmpty == false {
                navigationRouter.push(self.roomViewController, animated: true, popCompletion: nil)
            } else {
                navigationRouter.setRootModule(self.roomViewController, popCompletion: nil)
            }
        }
    }
        
    func start(withEventId eventId: String, completion: (() -> Void)?) {
        
        self.selectedEventId = eventId
        
        if self.hasStartedOnce {
            self.roomViewController.highlightAndDisplayEvent(eventId, completion: completion)
        } else {
            self.start(withCompletion: completion)
        }
    }

    func toPresentable() -> UIViewController {
        return self.roomViewController
    }

    // MARK: - Private

    private func loadRoom(withId roomId: String, completion: (() -> Void)?) {

        // Present activity indicator when retrieving roomDataSource for given room ID
        startLoading()

        let roomDataSourceManager: MXKRoomDataSourceManager = MXKRoomDataSourceManager.sharedManager(forMatrixSession: self.parameters.session)

        // LIVE: Show the room live timeline managed by MXKRoomDataSourceManager
        roomDataSourceManager.roomDataSource(forRoom: roomId, create: true, onComplete: { [weak self] (roomDataSource) in

            guard let self = self else {
                return
            }

            self.stopLoading()

            if let roomDataSource = roomDataSource {
                self.roomViewController.autoJoinInvitedRoom = self.parameters.autoJoinInvitedRoom
                self.roomViewController.displayRoom(roomDataSource)
            }
            
            self.mxSession?.updateBreadcrumbsWithRoom(withId: roomId, success: nil, failure: nil)

            completion?()
        })
    }

    private func loadRoom(withId roomId: String, andEventId eventId: String, completion: (() -> Void)?) {

        // Present activity indicator when retrieving roomDataSource for given room ID
        startLoading()

        // Open the room on the requested event
        RoomDataSource.load(withRoomId: roomId,
                            initialEventId: eventId,
                            threadId: nil,
                            andMatrixSession: self.parameters.session) { [weak self] (dataSource) in

            guard let self = self else {
                return
            }

            self.stopLoading()

            guard let roomDataSource = dataSource as? RoomDataSource else {
                return
            }

            roomDataSource.markTimelineInitialEvent = true
            self.roomViewController.displayRoom(roomDataSource)

            // Give the data source ownership to the room view controller.
            self.roomViewController.hasRoomDataSourceOwnership = true
            
            self.mxSession?.updateBreadcrumbsWithRoom(withId: roomId, success: nil, failure: nil)

            completion?()
        }
    }
    
    private func loadRoom(withId roomId: String, andThreadId threadId: String, eventId: String?, completion: (() -> Void)?) {
        
        // Present activity indicator when retrieving roomDataSource for given room ID
        startLoading()
        
        // Open the thread on the requested event
        ThreadDataSource.load(withRoomId: roomId,
                              initialEventId: eventId,
                              threadId: threadId,
                              andMatrixSession: self.parameters.session) { [weak self] (dataSource) in
            
            guard let self = self else {
                return
            }
            
            self.stopLoading()
            
            guard let threadDataSource = dataSource as? ThreadDataSource else {
                return
            }
            
            threadDataSource.markTimelineInitialEvent = false
            threadDataSource.highlightedEventId = eventId
            self.roomViewController.displayRoom(threadDataSource)
            
            // Give the data source ownership to the room view controller.
            self.roomViewController.hasRoomDataSourceOwnership = false
            
            self.mxSession?.updateBreadcrumbsWithRoom(withId: roomId, success: nil, failure: nil)

            completion?()
        }
    }
    
    private func loadRoom(withUserId userId: String) {
        // Start a new discussion
            
        // Present activity indicator when retrieving roomDataSource for given room ID
        startLoading()
        
        // Try to search target user if not exist in local session
        if let user = self.parameters.session.getOrCreateUser(userId) {
            if user.displayname != nil {
                // User has already been found from local session no update needed
                self.stopLoading()
                
                // Update RoomViewController with found target user
                self.roomViewController.displayNewDirectChat(withTargetUser: user, session: self.parameters.session)
            } else {
                // update user from homeserver
                user.update(fromHomeserverOfMatrixSession: self.parameters.session) {
                    self.stopLoading()
                    
                    self.parameters.session.store.store(user)
                    
                    // Update RoomViewController with found target user
                    self.roomViewController.displayNewDirectChat(withTargetUser: user, session: self.parameters.session)
                } failure: { [weak self] error in
                    guard let self = self else { return }
                    self.stopLoading()
                    
                    MXLog.error("[RoomCoordinator] User does not exist")
                    
                    // Alert user
                    self.displayError(message: VectorL10n.roomCreationDmError) { [weak self] in
                        guard let self = self else { return }
                        self.delegate?.roomCoordinatorDidCancelNewDirectChat(self)
                    }
                }
            }
        } else {
            self.stopLoading()
            
            self.displayError(message: VectorL10n.roomCreationDmError)
        }
    }
    
    private func loadRoomPreview(withData previewData: RoomPreviewData, completion: (() -> Void)?) {
        
        self.roomViewController.displayRoomPreview(previewData)
        
        completion?()
    }
    
    private func showLiveLocationViewer() {
        guard let roomId = self.roomId else {
            return
        }
        
        self.showLiveLocationViewer(for: roomId)
    }
    
    private func showLiveLocationViewer(for roomId: String) {
        
        guard let mxSession = self.mxSession, let navigationRouter = self.navigationRouter else {
            return
        }
        
        guard mxSession.locationService.isSomeoneSharingDisplayableLocation(inRoomWithId: roomId) else {
            return
        }
        
        let parameters = LiveLocationSharingViewerCoordinatorParameters(session: mxSession, roomId: roomId, navigationRouter: nil)
        
        let coordinator = LiveLocationSharingViewerCoordinator(parameters: parameters)
        
        coordinator.completion = { [weak self, weak coordinator] in
            guard let self = self, let coordinator = coordinator else {
                return
            }
            
            self.navigationRouter?.dismissModule(animated: true, completion: nil)
            self.remove(childCoordinator: coordinator)
        }
        
        add(childCoordinator: coordinator)
        
        navigationRouter.present(coordinator, animated: true)
        coordinator.start()
    }
    
    private func stopLiveLocationSharing(forBeaconInfoEventId beaconInfoEventId: String? = nil, inRoomWithId roomId: String) {
        guard let session = self.mxSession else {
            return
        }
        
        let errorHandler: (Error) -> Void = { error in
            
            let viewController = self.roomViewController
            
            viewController.errorPresenter.presentError(from: viewController, title: VectorL10n.error, message: VectorL10n.locationSharingLiveStopSharingError, animated: true) {
            }
        }
        
        // TODO: Handle loading state on the banner by replacing stop button with a spinner
        self.showLocationSharingIndicator(withMessage: VectorL10n.locationSharingLiveStopSharingProgress)
        
        if let beaconInfoEventId = beaconInfoEventId {
            session.locationService.stopUserLocationSharing(withBeaconInfoEventId: beaconInfoEventId, roomId: roomId) {
                [weak self] response in
                
                self?.hideLocationSharingIndicator()
                
                switch response {
                case .success:
                    break
                case .failure(let error):
                    errorHandler(error)
                }
            }
        } else {
            session.locationService.stopUserLocationSharing(inRoomWithId: roomId) { [weak self] response in
                
                self?.hideLocationSharingIndicator()
                
                switch response {
                case .success:
                    break
                case .failure(let error):
                    errorHandler(error)
                }
            }
        }
    }
    
    private func showLocationCoordinatorWithEvent(_ event: MXEvent, bubbleData: MXKRoomBubbleCellDataStoring) {
        guard let mxSession = self.mxSession,
              let navigationRouter = self.navigationRouter,
              let mediaManager = mxSession.mediaManager,
              let locationContent = event.location else {
                  MXLog.error("[RoomCoordinator] Invalid location showing coordinator parameters. Returning.")
                  return
              }
        
        let avatarData = AvatarInput(mxContentUri: bubbleData.senderAvatarUrl,
                                     matrixItemId: bubbleData.senderId,
                                     displayName: bubbleData.senderDisplayName)
        
        
        let location = CLLocationCoordinate2D(latitude: locationContent.latitude, longitude: locationContent.longitude)
        let coordinateType = locationContent.assetType
        
        guard let locationSharingCoordinatetype = coordinateType.locationSharingCoordinateType() else {
            fatalError("[LocationSharingCoordinator] event asset type is not supported: \(coordinateType)")
        }
        
        let parameters = StaticLocationViewingCoordinatorParameters(
            session: mxSession,
            mediaManager: mediaManager,
            avatarData: avatarData,
            location: location,
            coordinateType: locationSharingCoordinatetype)
        
        let coordinator = StaticLocationViewingCoordinator(parameters: parameters)
        
        coordinator.completion = { [weak self, weak coordinator] in
            guard let self = self, let coordinator = coordinator else {
                return
            }
            
            self.navigationRouter?.dismissModule(animated: true, completion: nil)
            self.remove(childCoordinator: coordinator)
        }
        
        add(childCoordinator: coordinator)
        
        navigationRouter.present(coordinator, animated: true)
        coordinator.start()
    }

    private func startLocationCoordinator() {
        guard let mxSession = mxSession,
              let navigationRouter = self.navigationRouter,
              let mediaManager = mxSession.mediaManager,
              let user = mxSession.myUser else {
            MXLog.error("[RoomCoordinator] Invalid location sharing coordinator parameters. Returning.")
            return
        }
        
        let avatarData = AvatarInput(mxContentUri: user.avatarUrl,
                                     matrixItemId: user.userId,
                                     displayName: user.displayname)
        
        let parameters = LocationSharingCoordinatorParameters(session: mxSession,
                                                              roomDataSource: roomViewController.roomDataSource,
                                                              mediaManager: mediaManager,
                                                              avatarData: avatarData)
        
        let coordinator = LocationSharingCoordinator(parameters: parameters)
        
        coordinator.completion = { [weak self, weak coordinator] in
            guard let self = self, let coordinator = coordinator else {
                return
            }
            
            self.navigationRouter?.dismissModule(animated: true, completion: nil)
            self.remove(childCoordinator: coordinator)
        }
        
        add(childCoordinator: coordinator)
        
        navigationRouter.present(coordinator, animated: true)
        coordinator.start()
    }
    
    private func startEditPollCoordinator(startEvent: MXEvent? = nil) {
        let parameters = PollEditFormCoordinatorParameters(room: roomViewController.roomDataSource.room, pollStartEvent: startEvent)
        let coordinator = PollEditFormCoordinator(parameters: parameters)
        
        coordinator.completion = { [weak self, weak coordinator] in
            guard let self = self, let coordinator = coordinator else {
                return
            }
            
            self.navigationRouter?.dismissModule(animated: true, completion: nil)
            self.remove(childCoordinator: coordinator)
        }
        
        add(childCoordinator: coordinator)
        
        navigationRouter?.present(coordinator, animated: true)
        coordinator.start()
    }
    
    private func startLoading() {
        // The `RoomViewController` does not currently ensure that `startLoading` is matched by corresponding `stopLoading` and may
        // thus trigger start of loading multiple times. To solve for this we will hold onto the cancellation reference of the
        // last loading request, and if one already exists, we will not present a new indicator.
        guard loadingCancel == nil else {
            return
        }
        
        MXLog.debug("[RoomCoordinator] Present loading indicator in a room: \(roomId ?? "unknown")")
        loadingCancel = userIndicatorStore.present(type: .loading(label: VectorL10n.homeSyncing, isInteractionBlocking: false))
    }
    
    private func stopLoading() {
        MXLog.debug("[RoomCoordinator] Dismiss loading indicator in a room: \(roomId ?? "unknown")")
        loadingCancel?()
        loadingCancel = nil
    }
    
    private func showLocationSharingIndicator(withMessage message: String) {
        guard locationSharingIndicatorCancel == nil else {
            return
        }
        
        locationSharingIndicatorCancel = userIndicatorStore.present(type: .loading(label: message, isInteractionBlocking: false))
    }
    
    private func hideLocationSharingIndicator() {
        locationSharingIndicatorCancel?()
        locationSharingIndicatorCancel = nil
    }
    
    private func displayError(message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: VectorL10n.error, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: VectorL10n.ok, style: .default) { _ in
            completion?()
        }
        alert.addAction(action)
        toPresentable().present(alert, animated: true)
    }
}

// MARK: - RoomIdentifiable
extension RoomCoordinator: RoomIdentifiable {
     
    var roomId: String? {
        return self.parameters.roomId
    }
    
    var threadId: String? {
        return self.parameters.threadId
    }
    
    var mxSession: MXSession? {
        self.parameters.session
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension RoomCoordinator: UIAdaptivePresentationControllerDelegate {
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        self.delegate?.roomCoordinatorDidDismissInteractively(self)
    }
}

// MARK: - RoomViewControllerDelegate
extension RoomCoordinator: RoomViewControllerDelegate {
        
    func roomViewController(_ roomViewController: RoomViewController, showRoomWithId roomID: String, eventId eventID: String?) {
        self.delegate?.roomCoordinator(self, didSelectRoomWithId: roomID, eventId: eventID)
    }
    
    func roomViewController(_ roomViewController: RoomViewController, didReplaceRoomWithReplacementId roomID: String) {
        self.delegate?.roomCoordinator(self, didReplaceRoomWithReplacementId: roomID)
    }
    
    func roomViewController(_ roomViewController: RoomViewController, showMemberDetails roomMember: MXRoomMember) {
        // TODO:
    }
    
    func roomViewControllerShowRoomDetails(_ roomViewController: RoomViewController) {
        // TODO:
    }
    
    func roomViewControllerDidLeaveRoom(_ roomViewController: RoomViewController) {
        self.delegate?.roomCoordinatorDidLeaveRoom(self)
    }
    
    func roomViewControllerPreviewDidTapCancel(_ roomViewController: RoomViewController) {
        self.delegate?.roomCoordinatorDidCancelRoomPreview(self)
    }
    
    func roomViewController(_ roomViewController: RoomViewController, startChatWithUserId userId: String, completion: @escaping () -> Void) {
        AppDelegate.theDelegate().showNewDirectChat(userId, withMatrixSession: self.mxSession, completion: completion)
    }
    
    func roomViewController(_ roomViewController: RoomViewController, showCompleteSecurityFor session: MXSession) {
        AppDelegate.theDelegate().presentCompleteSecurity(for: session)
    }
    
    func roomViewController(_ roomViewController: RoomViewController, handleUniversalLinkWith parameters: UniversalLinkParameters) -> Bool {
        return AppDelegate.theDelegate().handleUniversalLink(with: parameters)
    }
    
    func roomViewControllerDidRequestPollCreationFormPresentation(_ roomViewController: RoomViewController) {
        startEditPollCoordinator()
    }
    
    func roomViewControllerDidRequestLocationSharingFormPresentation(_ roomViewController: RoomViewController) {
        startLocationCoordinator()
    }
    
    func roomViewController(_ roomViewController: RoomViewController, didRequestLocationPresentationFor event: MXEvent, bubbleData: MXKRoomBubbleCellDataStoring) {
        showLocationCoordinatorWithEvent(event, bubbleData: bubbleData)
    }
    
    func roomViewController(_ roomViewController: RoomViewController, didRequestLiveLocationPresentationForBubbleData bubbleData: MXKRoomBubbleCellDataStoring) {
        
        guard let roomId = bubbleData.roomId else {
            return
        }
        
        showLiveLocationViewer(for: roomId)
    }
    
    func roomViewController(_ roomViewController: RoomViewController, locationShareActivityViewControllerFor event: MXEvent) -> UIActivityViewController? {
        guard let location = event.location else {
            return nil
        }
        
        return LocationSharingCoordinator.shareLocationActivityController(CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude))
    }
    
    func roomViewController(_ roomViewController: RoomViewController, canEndPollWithEventIdentifier eventIdentifier: String) -> Bool {
        return TimelinePollProvider.shared.timelinePollCoordinatorForEventIdentifier(eventIdentifier)?.canEndPoll() ?? false
    }
    
    func roomViewController(_ roomViewController: RoomViewController, endPollWithEventIdentifier eventIdentifier: String) {
        TimelinePollProvider.shared.timelinePollCoordinatorForEventIdentifier(eventIdentifier)?.endPoll()
    }
    
    func roomViewController(_ roomViewController: RoomViewController, canEditPollWithEventIdentifier eventIdentifier: String) -> Bool {
        return TimelinePollProvider.shared.timelinePollCoordinatorForEventIdentifier(eventIdentifier)?.canEditPoll() ?? false
    }
    
    func roomViewController(_ roomViewController: RoomViewController, didRequestEditForPollWithStart startEvent: MXEvent) {
        startEditPollCoordinator(startEvent: startEvent)
    }
    
    func roomViewControllerDidStartLoading(_ roomViewController: RoomViewController) {
        startLoading()
    }
    
    func roomViewControllerDidStopLoading(_ roomViewController: RoomViewController) {
        stopLoading()
    }
    
    func roomViewControllerDidTapLiveLocationSharingBanner(_ roomViewController: RoomViewController) {
        
        showLiveLocationViewer()
    }
    
    func roomViewControllerDidStopLiveLocationSharing(_ roomViewController: RoomViewController, beaconInfoEventId: String?) {
        
        guard let roomId = self.roomId else {
            return
        }
        
        self.stopLiveLocationSharing(forBeaconInfoEventId: beaconInfoEventId, inRoomWithId: roomId)
    }
    
    func threadsCoordinator(for roomViewController: RoomViewController, threadId: String?) -> ThreadsCoordinatorBridgePresenter? {
        guard let session = mxSession, let roomId = roomId else {
            MXLog.error("[RoomCoordinator] Cannot create threads coordinator for room", context: [
                "room_id": roomId
            ])
            return nil
        }
        
        return ThreadsCoordinatorBridgePresenter(
            session: session,
            roomId: roomId,
            threadId: threadId,
            userIndicatorPresenter: parameters.userIndicatorPresenter
        )
    }
}
