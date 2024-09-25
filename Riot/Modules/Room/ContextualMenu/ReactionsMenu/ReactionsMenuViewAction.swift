/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import UIKit

/// Action chosen by the user
enum ReactionsMenuViewAction {
    case loadData
    case tap(reaction: String)
    case moreReactions
}
