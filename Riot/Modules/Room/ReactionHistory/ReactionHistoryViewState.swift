// File created from ScreenTemplate
// $ createScreen.sh ReactionHistory ReactionHistory
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

/// ReactionHistoryViewController view state
enum ReactionHistoryViewState {
    case loading
    case loaded(reactionHistoryViewDataList: [ReactionHistoryViewData], allDataLoaded: Bool)
    case error(Error)
}
