// File created from ScreenTemplate
// $ createScreen.sh Room/EditHistory EditHistory
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol EditHistoryCoordinatorDelegate: AnyObject {
    func editHistoryCoordinatorDidComplete(_ coordinator: EditHistoryCoordinatorType)
}

/// `EditHistoryCoordinatorType` is a protocol describing a Coordinator that handle keybackup setup navigation flow.
protocol EditHistoryCoordinatorType: Coordinator, Presentable {
    var delegate: EditHistoryCoordinatorDelegate? { get }
}
