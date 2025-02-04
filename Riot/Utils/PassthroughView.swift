// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit

/**
 UIView subclass that ignores touches on itself.
 */
class PassthroughView: UIView {
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitTarget = super.hitTest(point, with: event)
        
        guard hitTarget == self else {
            return hitTarget
        }
        
        return nil
    }
}
