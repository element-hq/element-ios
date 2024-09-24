// File created from ScreenTemplate
// $ createScreen.sh Room Room
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol RoomCoordinatorDelegate: AnyObject {
    func roomCoordinatorDidLeaveRoom(_ coordinator: RoomCoordinatorProtocol)
    func roomCoordinatorDidCancelRoomPreview(_ coordinator: RoomCoordinatorProtocol)
    func roomCoordinator(_ coordinator: RoomCoordinatorProtocol, didSelectRoomWithId roomId: String, eventId: String?)
    func roomCoordinator(_ coordinator: RoomCoordinatorProtocol, didReplaceRoomWithReplacementId roomId: String)
    func roomCoordinatorDidDismissInteractively(_ coordinator: RoomCoordinatorProtocol)
    func roomCoordinatorDidCancelNewDirectChat(_ coordinator: RoomCoordinatorProtocol)
}

/// `RoomCoordinatorProtocol` is a protocol describing a Coordinator that handle room navigation flow.
protocol RoomCoordinatorProtocol: Coordinator, Presentable, RoomIdentifiable {
    var delegate: RoomCoordinatorDelegate? { get }
    
    // Indicate if the underlying RoomDataSource can be released
    var canReleaseRoomDataSource: Bool { get }
    
    /// Start the Coordinator with a setup completion.
    /// NOTE: Completion closure has been added for legacy architecture purpose.
    /// Remove this completion after LegacyAppDelegate refactor.
    /// - Parameters:
    ///   - completion: called when the RoomDataSource has finish to load.
    func start(withCompletion completion: (() -> Void)?)
    
    /// Use this method when the room screen is already shown and you want to go to a specific event.
    /// i.e User tap on push notification message for the current displayed room
    /// - Parameters:
    ///   - eventId: The id of the event to display.
    ///   - completion: called when the RoomDataSource has finish to load.
    func start(withEventId eventId: String, completion: (() -> Void)?)
}
