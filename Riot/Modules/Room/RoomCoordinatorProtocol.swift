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
