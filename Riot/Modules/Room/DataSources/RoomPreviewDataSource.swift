// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// `RoomPreviewDataSource` is used for room context menu.
@objcMembers
public class RoomPreviewDataSource: RoomDataSource {
    
    public override func finalizeInitialization() {
        super.finalizeInitialization()
        showReadMarker = false
        showBubbleReceipts = false
        showTypingRow = false
    }
    
    public override var showReadMarker: Bool {
        get {
            return false
        } set {
            _ = newValue
        }
    }
    
    public override var showBubbleReceipts: Bool {
        get {
            return false
        } set {
            _ = newValue
        }
    }
    
}
