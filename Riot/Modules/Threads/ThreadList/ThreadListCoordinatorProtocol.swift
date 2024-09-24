// File created from ScreenTemplate
// $ createScreen.sh Threads/ThreadList ThreadList
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol ThreadListCoordinatorDelegate: AnyObject {
    func threadListCoordinatorDidLoadThreads(_ coordinator: ThreadListCoordinatorProtocol)
    func threadListCoordinatorDidSelectThread(_ coordinator: ThreadListCoordinatorProtocol, thread: MXThreadProtocol)
    func threadListCoordinatorDidSelectRoom(_ coordinator: ThreadListCoordinatorProtocol, roomId: String, eventId: String)
    func threadListCoordinatorDidCancel(_ coordinator: ThreadListCoordinatorProtocol)
}

/// `ThreadListCoordinatorProtocol` is a protocol describing a Coordinator that handle thread list navigation flow.
protocol ThreadListCoordinatorProtocol: Coordinator, Presentable {
    var delegate: ThreadListCoordinatorDelegate? { get }
}
