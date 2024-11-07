// File created from SimpleUserProfileExample
// $ createScreen.sh Spaces/SpaceCreation/SpaceCreationPostProcess SpaceCreationPostProcess
//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

struct SpaceCreationPostProcessCoordinatorParameters {
    let session: MXSession
    let parentSpaceId: String?
    let creationParams: SpaceCreationParameters
}
