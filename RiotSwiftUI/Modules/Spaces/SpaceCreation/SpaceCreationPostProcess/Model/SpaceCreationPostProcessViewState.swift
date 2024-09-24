// File created from SimpleUserProfileExample
// $ createScreen.sh Spaces/SpaceCreation/SpaceCreationPostProcess SpaceCreationPostProcess
//
// Copyright 2017-2024 New Vector Ltd
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
