// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// A collection of helpful functions for media compression.
class MediaCompressionHelper: NSObject {
    /// The default compression mode taking into account the `roomInputToolbarCompressionMode` build setting
    /// and the `showMediaCompressionPrompt` Riot setting.
    @objc static var defaultCompressionMode: MXKRoomInputToolbarCompressionMode {
        // When the compression mode build setting hasn't been customised, use the media compression prompt setting to determine what to do.
        if BuildSettings.roomInputToolbarCompressionMode == .prompt {
            return RiotSettings.shared.showMediaCompressionPrompt ? MXKRoomInputToolbarCompressionModePrompt : MXKRoomInputToolbarCompressionModeNone
        } else {
            // Otherwise use the compression mode defined in the build settings.
            return BuildSettings.roomInputToolbarCompressionMode.mxkCompressionMode
        }
    }
}

extension BuildSettings.MediaCompressionMode {
    /// The compression mode as an `MXKRoomInputToolbarCompressionMode` value.
    var mxkCompressionMode: MXKRoomInputToolbarCompressionMode {
        switch self {
        case .prompt:
            return MXKRoomInputToolbarCompressionModePrompt
        case .small:
            return MXKRoomInputToolbarCompressionModeSmall
        case .medium:
            return MXKRoomInputToolbarCompressionModeMedium
        case .large:
            return MXKRoomInputToolbarCompressionModeLarge
        case .none:
            return MXKRoomInputToolbarCompressionModeNone
        }
    }
}
