//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

extension XCUIElement {
    func forceTap() {
        if isHittable {
            tap()
        } else {
            let coordinate: XCUICoordinate = coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5))
            coordinate.tap()
        }
    }
}
