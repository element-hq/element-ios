//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// A protocol that any class or struct can conform to
/// so that it can easily produce avatar data.
///
/// E.g. MXRoom, MxUser can conform to this making it
/// easy to grab the avatar data for display.
protocol Avatarable: AvatarInputProtocol { }
extension Avatarable {
    var avatarData: AvatarInput {
        AvatarInput(
            mxContentUri: mxContentUri,
            matrixItemId: matrixItemId,
            displayName: displayName
        )
    }
}
