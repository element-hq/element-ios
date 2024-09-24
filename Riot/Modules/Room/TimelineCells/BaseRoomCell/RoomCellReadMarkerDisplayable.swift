// 
// Copyright 2024 New Vector Ltd
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import UIKit

/// `RoomCellReadMarkerDisplayable` is a protocol indicating that a cell support displaying read marker.
@objc protocol RoomCellReadMarkerDisplayable {    
    func addReadMarkerView(_ readMarkerView: UIView)
    func removeReadMarkerView()
}
