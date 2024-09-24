// File created from ScreenTemplate
// $ createScreen.sh Spaces/SpaceMembers/MemberDetail ShowSpaceMemberDetail
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

/// SpaceMemberDetailViewController view state
enum SpaceMemberDetailViewState {
    case loading
    case loaded(MXRoomMember, MXRoom?)
    case error(Error)
}
