/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import UIKit

extension UIStackView {
    
    func vc_removeAllArrangedSubviews() {
        let subviews = self.arrangedSubviews
        for subview in subviews {
            self.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }
    }
}
