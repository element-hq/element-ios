// File created from SimpleUserProfileExample
// $ createScreen.sh Spaces/SpaceCreation/SpaceCreationEmailInvites SpaceCreationEmailInvites
//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

protocol SpaceCreationEmailInvitesViewModelProtocol {
    var completion: ((SpaceCreationEmailInvitesViewModelResult) -> Void)? { get set }
    var context: SpaceCreationEmailInvitesViewModelType.Context { get }
}
