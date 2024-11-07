// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

/// `RoomCellThreadSummaryDisplayable` is a protocol indicating that a cell support displaying a thread summary.
@objc protocol RoomCellThreadSummaryDisplayable {
    func addThreadSummaryView(_ threadSummaryView: ThreadSummaryView)
    func removeThreadSummaryView()
}
