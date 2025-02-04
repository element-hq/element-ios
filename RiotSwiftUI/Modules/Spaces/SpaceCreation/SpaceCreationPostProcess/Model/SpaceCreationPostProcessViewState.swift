// File created from SimpleUserProfileExample
// $ createScreen.sh Spaces/SpaceCreation/SpaceCreationPostProcess SpaceCreationPostProcess
//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import UIKit

struct SpaceCreationPostProcessViewState: BindableState {
    var avatar: AvatarInput
    var avatarImage: UIImage?
    var tasks: [SpaceCreationPostProcessTask]
    var isFinished: Bool
    var errorCount: Int
}
