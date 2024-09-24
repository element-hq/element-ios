// File created from ScreenTemplate
// $ createScreen.sh ReactionHistory ReactionHistory
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol ReactionHistoryCoordinatorDelegate: AnyObject {
    func reactionHistoryCoordinatorDidClose(_ coordinator: ReactionHistoryCoordinatorType)
}

/// `ReactionHistoryCoordinatorType` is a protocol describing a Coordinator that handle reaction history navigation flow.
protocol ReactionHistoryCoordinatorType: Coordinator, Presentable {
    var delegate: ReactionHistoryCoordinatorDelegate? { get }
}
