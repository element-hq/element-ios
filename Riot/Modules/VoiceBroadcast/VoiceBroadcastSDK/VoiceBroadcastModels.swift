// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

public enum VoiceBroadcastKind {
    case player
    case recorder
}

public struct VoiceBroadcast {
    var chunks: Set<VoiceBroadcastChunk> = []
    var kind: VoiceBroadcastKind = .player
    var duration: UInt = 0
}
