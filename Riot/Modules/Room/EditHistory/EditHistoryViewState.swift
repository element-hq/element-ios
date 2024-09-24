// File created from ScreenTemplate
// $ createScreen.sh Room/EditHistory EditHistory
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

/// EditHistoryViewController view state
enum EditHistoryViewState {
    case loading
    case loaded(sections: [EditHistorySection], addedCount: Int, allDataLoaded: Bool)
    case error(Error)
}
