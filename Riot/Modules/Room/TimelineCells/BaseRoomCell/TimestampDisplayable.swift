// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit

/// `TimestampDisplayable` is a protocol indicating that a view supports displaying a timestamp.
@objc protocol TimestampDisplayable {
    func addTimestampView(_ timestampView: UIView)
    func removeTimestampView()
}
