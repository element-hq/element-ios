// 
// Copyright 2024 New Vector Ltd
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

/// `RoomCellURLPreviewDisplayable` is a protocol indicating that a cell support displaying a URL preview.
@objc protocol RoomCellURLPreviewDisplayable {
    func addURLPreviewView(_ urlPreviewView: UIView)
    func removeURLPreviewView()
}
