// File created from ScreenTemplate
// $ createScreen.sh Spaces/SpaceMembers/MemberList ShowSpaceMemberList
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

/// SpaceMemberListViewController view actions exposed to view model
enum SpaceMemberListViewAction {
    case loadData
    case complete(_ selectedMember: MXRoomMember, _ sourceView: UIView?)
    case cancel
    case invite
}
