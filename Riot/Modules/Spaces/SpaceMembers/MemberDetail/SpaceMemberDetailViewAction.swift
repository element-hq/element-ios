// File created from ScreenTemplate
// $ createScreen.sh Spaces/SpaceMembers/MemberDetail ShowSpaceMemberDetail
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

/// SpaceMemberDetailViewController view actions exposed to view model
enum SpaceMemberDetailViewAction {
    case loadData
    case openRoom(_ roomId: String)
    case createRoom(_ memberId: String)
    case cancel
}
