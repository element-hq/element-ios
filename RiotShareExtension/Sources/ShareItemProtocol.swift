// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

@objc public enum ShareItemType: UInt {
    case fileURL, text, URL, image, video, movie, unknown
}

@objc public protocol ShareItemProtocol {
    var type: ShareItemType { get }
}
