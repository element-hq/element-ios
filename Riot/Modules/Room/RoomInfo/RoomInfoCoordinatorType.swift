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

import Foundation
import MatrixSDK

protocol RoomInfoCoordinatorDelegate: AnyObject {
    func roomInfoCoordinatorDidComplete(_ coordinator: RoomInfoCoordinatorType)
    func roomInfoCoordinator(_ coordinator: RoomInfoCoordinatorType, didRequestMentionForMember member: MXRoomMember)
    func roomInfoCoordinatorDidLeaveRoom(_ coordinator: RoomInfoCoordinatorType)
    func roomInfoCoordinator(_ coordinator: RoomInfoCoordinatorType, didReplaceRoomWithReplacementId roomId: String)
    func roomInfoCoordinator(_ coordinator: RoomInfoCoordinatorType, viewEventInTimeline event: MXEvent)
    func roomInfoCoordinatorDidRequestReportRoom(_ coordinator: RoomInfoCoordinatorType)
}

/// `RoomInfoCoordinatorType` is a protocol describing a Coordinator that handle keybackup setup navigation flow.
protocol RoomInfoCoordinatorType: Coordinator, Presentable {
    var delegate: RoomInfoCoordinatorDelegate? { get }
}
