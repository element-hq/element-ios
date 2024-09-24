// File created from ScreenTemplate
// $ createScreen.sh Threads/ThreadList ThreadList
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

/// ThreadListViewController view state
enum ThreadListViewState {
    case idle
    case loading
    case loaded
    case empty(_ viewModel: ThreadListEmptyModel)
    case showingFilterTypes
    case showingLongPressActions(_ index: Int)
    case share(_ url: URL, _ index: Int)
    case toastForCopyLink
    case error(Error)
}
