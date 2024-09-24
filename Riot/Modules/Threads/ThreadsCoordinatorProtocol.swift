// File created from FlowTemplate
// $ createRootCoordinator.sh Threads Threads ThreadList
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
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
