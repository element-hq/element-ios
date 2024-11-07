// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

@objc
public enum RecentsListServiceSection: Int {
    case invited
    case favorited
    case people
    case conversation
    case lowPriority
    case serverNotice
    case suggested
    case allChats
    case breadcrumbs
}
