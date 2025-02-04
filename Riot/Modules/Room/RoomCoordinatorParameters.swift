// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// RoomCoordinator input parameters
struct RoomCoordinatorParameters {
    
    // MARK: - Properties
    
    /// The navigation router that manage physical navigation
    let navigationRouter: NavigationRouterType?
    
    /// The navigation router store that enables to get a NavigationRouter from a navigation controller
    /// `navigationRouter` property takes priority on `navigationRouterStore`
    let navigationRouterStore: NavigationRouterStoreProtocol?
    
    /// Presenter for displaying loading indicators, success messages and other user indicators
    let userIndicatorPresenter: UserIndicatorTypePresenterProtocol
    
    /// The matrix session in which the room should be available.
    let session: MXSession
    
    /// The room identifier. `nil` on new DM
    let roomId: String?
    
    /// The identifier of the parent space. `nil` for home space
    let parentSpaceId: String?

    /// If not nil, the room will be opened on this event.
    let eventId: String?
    
    /// If not nil, specified thread will be opened.
    let threadId: String?
    
    /// The user identifier to create a new DM
    let userId: String?
    
    /// Display configuration for the room
    let displayConfiguration: RoomDisplayConfiguration
    
    /// The data for the room preview.
    let previewData: RoomPreviewData?
    
    /// If `true`, the room settings screen will be initially displayed. Default `false`
    let showSettingsInitially: Bool
    
    /// If `true`, the invited room is automatically joined.
    let autoJoinInvitedRoom: Bool
    
    // MARK: - Setup
    
    private init(navigationRouter: NavigationRouterType?,
                 navigationRouterStore: NavigationRouterStoreProtocol?,
                 userIndicatorPresenter: UserIndicatorTypePresenterProtocol,
                 session: MXSession,
                 roomId: String?,
                 parentSpaceId: String?,
                 eventId: String?,
                 threadId: String?,
                 userId: String?,
                 displayConfiguration: RoomDisplayConfiguration,
                 previewData: RoomPreviewData?,
                 showSettingsInitially: Bool,
                 autoJoinInvitedRoom: Bool) {
        self.navigationRouter = navigationRouter
        self.navigationRouterStore = navigationRouterStore
        self.userIndicatorPresenter = userIndicatorPresenter
        self.session = session
        self.roomId = roomId
        self.parentSpaceId = parentSpaceId
        self.eventId = eventId
        self.threadId = threadId
        self.userId = userId
        self.displayConfiguration = displayConfiguration
        self.previewData = previewData
        self.showSettingsInitially = showSettingsInitially
        self.autoJoinInvitedRoom = autoJoinInvitedRoom
    }
    
    /// Init to present a joined room
    init(navigationRouter: NavigationRouterType? = nil,
         navigationRouterStore: NavigationRouterStoreProtocol? = nil,
         userIndicatorPresenter: UserIndicatorTypePresenterProtocol,
         session: MXSession,
         parentSpaceId: String?,
         roomId: String?,
         eventId: String? = nil,
         threadId: String? = nil,
         userId: String? = nil,
         showSettingsInitially: Bool,
         displayConfiguration: RoomDisplayConfiguration = .default,
         autoJoinInvitedRoom: Bool = false) {
        
        self.init(navigationRouter: navigationRouter,
                  navigationRouterStore: navigationRouterStore,
                  userIndicatorPresenter: userIndicatorPresenter,
                  session: session,
                  roomId: roomId,
                  parentSpaceId: parentSpaceId,
                  eventId: eventId,
                  threadId: threadId,
                  userId: userId,
                  displayConfiguration: displayConfiguration,
                  previewData: nil,
                  showSettingsInitially: showSettingsInitially,
                  autoJoinInvitedRoom: autoJoinInvitedRoom)
    }
    
    /// Init to present a room preview
    init(navigationRouter: NavigationRouterType? = nil,
         navigationRouterStore: NavigationRouterStoreProtocol? = nil,
         userIndicatorPresenter: UserIndicatorTypePresenterProtocol,
         parentSpaceId: String?,
         previewData: RoomPreviewData) {
        
        self.init(navigationRouter: navigationRouter,
                  navigationRouterStore: navigationRouterStore,
                  userIndicatorPresenter: userIndicatorPresenter,
                  session: previewData.mxSession,
                  roomId: previewData.roomId,
                  parentSpaceId: parentSpaceId,
                  eventId: nil,
                  threadId: nil,
                  userId: nil,
                  displayConfiguration: .default,
                  previewData: previewData,
                  showSettingsInitially: false,
                  autoJoinInvitedRoom: false)
    }
}
