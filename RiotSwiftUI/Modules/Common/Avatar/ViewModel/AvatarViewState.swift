//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import UIKit

enum AvatarViewState {
    case empty
    case placeholder(Character, Int)
    case avatar(UIImage)
}
