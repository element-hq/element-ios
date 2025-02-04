// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// `RoomIdentifiable` describes an object tied to a specific room id.
/// Useful to identify existing objects that should be removed when the user leaves a room for example.
protocol RoomIdentifiable {
    var roomId: String? { get }
    var threadId: String? { get }
    var mxSession: MXSession? { get }
}
