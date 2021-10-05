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
    func roomCoordinator(_ coordinator: RoomCoordinatorProtocol, didSelectRoomWithId roomId: String)
    func roomCoordinatorDidDismissInteractively(_ coordinator: RoomCoordinatorProtocol)
}

/// `RoomCoordinatorProtocol` is a protocol describing a Coordinator that handle key backup setup passphrase navigation flow.
protocol RoomCoordinatorProtocol: Coordinator, Presentable, RoomIdentifiable {
    var delegate: RoomCoordinatorDelegate? { get }
    
    var canReleaseRoomDataSource: Bool { get }
}
