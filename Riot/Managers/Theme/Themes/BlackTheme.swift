/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import UIKit

class BlackTheme: DarkTheme {

    override init() {
        super.init()
        self.identifier = ThemeIdentifier.black.rawValue
        self.backgroundColor = UIColor(rgb: 0x000000)
        self.headerBorderColor = UIColor(rgb: 0x15191E)
    }
    
    override var baseColor: UIColor {
        UIColor(rgb: 0x000000)
    }
    
    override var headerBackgroundColor: UIColor {
        UIColor(rgb: 0x000000)
    }
}
