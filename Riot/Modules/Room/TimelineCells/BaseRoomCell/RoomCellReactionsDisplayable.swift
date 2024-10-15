/*
Copyright 2020-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

/// `RoomCellReactionsDisplayable` is a protocol indicating that a cell support displaying reactions.
@objc protocol RoomCellReactionsDisplayable {
    func addReactionsView(_ reactionsView: UIView)
    func removeReactionsView()
}
