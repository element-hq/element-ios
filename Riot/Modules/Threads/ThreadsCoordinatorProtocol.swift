// File created from FlowTemplate
// $ createRootCoordinator.sh Threads Threads ThreadList
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

protocol ThreadsCoordinatorDelegate: AnyObject {
    func threadsCoordinatorDidComplete(_ coordinator: ThreadsCoordinatorProtocol)
    
    func threadsCoordinatorDidSelect(_ coordinator: ThreadsCoordinatorProtocol, roomId: String, eventId: String?)
    
    /// Called when the view has been dismissed by gesture when presented modally (not in full screen).
    func threadsCoordinatorDidDismissInteractively(_ coordinator: ThreadsCoordinatorProtocol)
}

/// `ThreadsCoordinatorProtocol` is a protocol describing a Coordinator that handle xxxxxxx navigation flow.
protocol ThreadsCoordinatorProtocol: Coordinator, Presentable {
    var delegate: ThreadsCoordinatorDelegate? { get }
}
