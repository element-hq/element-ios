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

final class RoomCoordinator: NSObject, RoomCoordinatorProtocol {

    // MARK: - Properties

    // MARK: Private

    private let parameters: RoomCoordinatorParameters
    private let roomViewController: RoomViewController
    private let activityIndicatorPresenter: ActivityIndicatorPresenterType
    private var selectedEventId: String?
    
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
        return self.parameters.previewData == nil && self.roomViewController.roomDataSource != nil && self.roomViewController.hasRoomDataSourceOwnership == false
    }
    
    // MARK: - Setup

    init(parameters: RoomCoordinatorParameters) {
        self.parameters = parameters
        self.selectedEventId = parameters.eventId

        self.roomViewController = RoomViewController.instantiate()
        self.activityIndicatorPresenter = ActivityIndicatorPresenter()
        
        if #available(iOS 14, *) {
            TimelinePollProvider.shared.session = parameters.session
        }
        
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
        } else if let eventId = self.selectedEventId {
            self.loadRoom(withId: self.parameters.roomId, and: eventId, completion: completion)
        } else {
            self.loadRoom(withId: self.parameters.roomId, completion: completion)
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
            self.loadRoom(withId: self.parameters.roomId, and: eventId, completion: completion)
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
        self.activityIndicatorPresenter.presentActivityIndicator(on: roomViewController.view, animated: false)

        let roomDataSourceManager: MXKRoomDataSourceManager = MXKRoomDataSourceManager.sharedManager(forMatrixSession: self.parameters.session)

        // LIVE: Show the room live timeline managed by MXKRoomDataSourceManager
        roomDataSourceManager.roomDataSource(forRoom: roomId, create: true, onComplete: { [weak self] (roomDataSource) in

            guard let self = self else {
                return
            }

            self.activityIndicatorPresenter.removeCurrentActivityIndicator(animated: true)

            if let roomDataSource = roomDataSource {
                self.roomViewController.displayRoom(roomDataSource)
            }
            
            completion?()
        })
    }

    private func loadRoom(withId roomId: String, and eventId: String, completion: (() -> Void)?) {

        // Present activity indicator when retrieving roomDataSource for given room ID
        self.activityIndicatorPresenter.presentActivityIndicator(on: roomViewController.view, animated: false)

        // Open the room on the requested event
        RoomDataSource.load(withRoomId: roomId,
                            initialEventId: eventId,
                            andMatrixSession: self.parameters.session) { [weak self] (dataSource) in

            guard let self = self else {
                return
            }

            self.activityIndicatorPresenter.removeCurrentActivityIndicator(animated: true)

            guard let roomDataSource = dataSource as? RoomDataSource else {
                return
            }

            roomDataSource.markTimelineInitialEvent = true
            self.roomViewController.displayRoom(roomDataSource)

            // Give the data source ownership to the room view controller.
            self.roomViewController.hasRoomDataSourceOwnership = true
            
            completion?()
        }
    }
    
    private func loadRoomPreview(withData previewData: RoomPreviewData, completion: (() -> Void)?) {
        
        self.roomViewController.displayRoomPreview(previewData)
        
        completion?()
    }
    
    private func startLocationCoordinatorWithEvent(_ event: MXEvent? = nil, bubbleData: MXKRoomBubbleCellDataStoring? = nil) {
        guard #available(iOS 14.0, *) else {
            return
        }
        
        guard let navigationRouter = self.navigationRouter,
              let mediaManager = mxSession?.mediaManager,
              let user = mxSession?.myUser else {
            MXLog.error("[RoomCoordinator] Invalid location sharing coordinator parameters. Returning.")
            return
        }
        
        var avatarData: AvatarInputProtocol
        if event != nil, let bubbleData = bubbleData {
            avatarData = AvatarInput(mxContentUri: bubbleData.senderAvatarUrl,
                                     matrixItemId: bubbleData.senderId,
                                     displayName: bubbleData.senderDisplayName)
        } else {
            avatarData = AvatarInput(mxContentUri: user.avatarUrl,
                                     matrixItemId: user.userId,
                                     displayName: user.displayname)
        }
        
        var location: CLLocationCoordinate2D?
        if let locationContent = event?.location {
            location = CLLocationCoordinate2D(latitude: locationContent.latitude, longitude: locationContent.longitude)
        }
        
        let parameters = LocationSharingCoordinatorParameters(roomDataSource: roomViewController.roomDataSource,
                                                              mediaManager: mediaManager,
                                                              avatarData: avatarData,
                                                              location: location)
        
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
        guard #available(iOS 14.0, *) else {
            return
        }
        
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
}

// MARK: - RoomIdentifiable
extension RoomCoordinator: RoomIdentifiable {
     
    var roomId: String? {
        return self.parameters.roomId
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
        
    func roomViewController(_ roomViewController: RoomViewController, showRoomWithId roomID: String) {
        self.delegate?.roomCoordinator(self, didSelectRoomWithId: roomID)
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
        AppDelegate.theDelegate().createDirectChat(withUserId: userId, completion: completion)
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
        startLocationCoordinatorWithEvent()
    }
    
    func roomViewController(_ roomViewController: RoomViewController, didRequestLocationPresentationFor event: MXEvent, bubbleData: MXKRoomBubbleCellDataStoring) {
        startLocationCoordinatorWithEvent(event, bubbleData: bubbleData)
    }
    
    func roomViewController(_ roomViewController: RoomViewController, canEndPollWithEventIdentifier eventIdentifier: String) -> Bool {
        guard #available(iOS 14.0, *) else {
            return false
        }
        
        return TimelinePollProvider.shared.timelinePollCoordinatorForEventIdentifier(eventIdentifier)?.canEndPoll() ?? false
    }
    
    func roomViewController(_ roomViewController: RoomViewController, endPollWithEventIdentifier eventIdentifier: String) {
        guard #available(iOS 14.0, *) else {
            return
        }
        
        TimelinePollProvider.shared.timelinePollCoordinatorForEventIdentifier(eventIdentifier)?.endPoll()
    }
    
    func roomViewController(_ roomViewController: RoomViewController, canEditPollWithEventIdentifier eventIdentifier: String) -> Bool {
        guard #available(iOS 14.0, *) else {
            return false
        }
        
        return TimelinePollProvider.shared.timelinePollCoordinatorForEventIdentifier(eventIdentifier)?.canEditPoll() ?? false
    }
    
    func roomViewController(_ roomViewController: RoomViewController, didRequestEditForPollWithStart startEvent: MXEvent) {
        startEditPollCoordinator(startEvent: startEvent)
    }
}
