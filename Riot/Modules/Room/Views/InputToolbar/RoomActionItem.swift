// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import UIKit

@objcMembers
class RoomActionItem: NSObject {
    let image: UIImage
    let action: (() -> Void)

    init(image: UIImage, andAction action: @escaping () -> Void) {
        self.image = image
        self.action = action
        
        super.init()
    }
}
