/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

/// Model for "im.vector.setting.allowed_widgets"
/// https://github.com/vector-im/riot-meta/blob/master/spec/settings.md#tracking-which-widgets-the-user-has-allowed-to-load
struct RiotSettingAllowedWidgets {
    let widgets: [String: Bool]

    // Widget type -> Server domain -> Bool
    let nativeWidgets: [String: [String: Bool]]
}

extension RiotSettingAllowedWidgets: Decodable {
    enum CodingKeys: String, CodingKey {
        case widgets
        case nativeWidgets = "native_widgets"
    }
}
