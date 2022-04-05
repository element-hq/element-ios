// 
// Copyright 2021 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
