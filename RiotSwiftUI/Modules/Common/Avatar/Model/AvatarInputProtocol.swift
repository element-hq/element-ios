//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

protocol AvatarInputProtocol: AvatarProtocol {
    var mxContentUri: String? { get }
    var matrixItemId: String { get }
    var displayName: String? { get }
}

struct AvatarInput: AvatarInputProtocol {
    let mxContentUri: String?
    var matrixItemId: String
    let displayName: String?
}

extension AvatarInput: Equatable { }
