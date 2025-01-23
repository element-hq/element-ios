// File created from SimpleUserProfileExample
// $ createScreen.sh Spaces/SpaceCreation/SpaceCreationEmailInvites SpaceCreationEmailInvites
//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

struct SpaceCreationEmailInvitesViewState: BindableState {
    var title: String
    var emailAddressesValid: [Bool]
    var loading: Bool
    var bindings: SpaceCreationEmailInvitesViewModelBindings
}
