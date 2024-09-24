// File created from ScreenTemplate
// $ createScreen.sh Room/ParticipantsInviteModal/OptionList OptionList
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

/// OptionListViewController view actions exposed to view model
enum OptionListViewAction {
    case loadData
    case selected(_ index: Int)
    case cancel
}
