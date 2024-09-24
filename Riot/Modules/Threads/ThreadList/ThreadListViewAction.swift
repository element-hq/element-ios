// File created from ScreenTemplate
// $ createScreen.sh Threads/ThreadList ThreadList
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

/// ThreadListViewController view actions exposed to view model
enum ThreadListViewAction {
    case loadData
    case complete
    case showFilterTypes
    case selectFilterType(_ type: ThreadListFilterType)
    case selectThread(_ index: Int)
    case longPressThread(_ index: Int)
    case actionViewInRoom
    case actionCopyLinkToThread
    case actionShare
    case cancel
}
