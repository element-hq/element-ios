// File created from ScreenTemplate
// $ createScreen.sh Room/ParticipantsInviteModal/OptionList OptionList
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

/// OptionListViewController view state
enum OptionListViewState {
    case idle
    case loading
    case loaded(_ title: String?, _ options: [OptionListItemViewData])
    case error(Error)
}
