/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import UIKit

extension UIGestureRecognizer {
    
    func vc_isTouchingInside(view: UIView? = nil) -> Bool {
        guard let view = view ?? self.view else {
            return false
        }
        let touchedLocation = self.location(in: view)
        return view.bounds.contains(touchedLocation)
    }
}
